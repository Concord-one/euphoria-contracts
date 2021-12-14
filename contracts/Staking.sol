// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./Policy.sol";
import "./libraries/CustomSafeMath.sol";
import "./libraries/SafeERC20.sol";
import "./interfaces/ISCCRD.sol";
import "./interfaces/IWarmup.sol";
import "./interfaces/IDistributor.sol";

contract Staking is Policy {
    using CustomSafeMath for uint256;
    using CustomSafeMath for uint32;
    using SafeERC20 for IERC20;

    address public immutable WAGMI;
    address public immutable sConcord;

    struct Epoch {
        uint256 number;
        uint256 distribute;
        uint32 duration;
        uint32 endTime;
    }
    Epoch public epoch;

    address public distributor;

    address public locker;
    uint256 public totalBonus;

    address public warmupContract;
    uint256 public warmupPeriod;

    constructor(
        address _WAGMI,
        address _sConcord,
        uint32 _duration,
        uint256 _firstEpochNumber,
        uint32 _firstEpochTime
    ) {
        require(_WAGMI != address(0));
        WAGMI = _WAGMI;
        require(_sConcord != address(0));
        sConcord = _sConcord;

        epoch = Epoch({duration: _duration, number: _firstEpochNumber, endTime: _firstEpochTime, distribute: 0});
    }

    struct Claim {
        uint256 deposit;
        uint256 gons;
        uint256 expiry;
        bool lock; // prevents malicious delays
    }
    mapping(address => Claim) public warmupInfo;

    /**
        @notice stake OHM to enter warmup
        @param _amount uint
        @return bool
     */
    function stake(uint256 _amount, address _recipient) external returns (bool) {
        rebase();

        IERC20(WAGMI).safeTransferFrom(msg.sender, address(this), _amount);

        Claim memory info = warmupInfo[_recipient];
        require(!info.lock, "Deposits for account are locked");

        warmupInfo[_recipient] = Claim({
            deposit: info.deposit.add(_amount),
            gons: info.gons.add(ISCCRD(sConcord).gonsForBalance(_amount)),
            expiry: epoch.number.add(warmupPeriod),
            lock: false
        });

        IERC20(sConcord).safeTransfer(warmupContract, _amount);
        return true;
    }

    /**
        @notice retrieve sOHM from warmup
        @param _recipient address
     */
    function claim(address _recipient) public {
        Claim memory info = warmupInfo[_recipient];
        if (epoch.number >= info.expiry && info.expiry != 0) {
            delete warmupInfo[_recipient];
            IWarmup(warmupContract).retrieve(_recipient, ISCCRD(sConcord).balanceForGons(info.gons));
        }
    }

    /**
        @notice forfeit sOHM in warmup and retrieve OHM
     */
    function forfeit() external {
        Claim memory info = warmupInfo[msg.sender];
        delete warmupInfo[msg.sender];

        IWarmup(warmupContract).retrieve(address(this), ISCCRD(sConcord).balanceForGons(info.gons));
        IERC20(WAGMI).safeTransfer(msg.sender, info.deposit);
    }

    /**
        @notice prevent new deposits to address (protection from malicious activity)
     */
    function toggleDepositLock() external {
        warmupInfo[msg.sender].lock = !warmupInfo[msg.sender].lock;
    }

    /**
        @notice redeem sOHM for OHM
        @param _amount uint
        @param _trigger bool
     */
    function unstake(uint256 _amount, bool _trigger) external {
        if (_trigger) {
            rebase();
        }
        IERC20(sConcord).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(WAGMI).safeTransfer(msg.sender, _amount);
    }

    /**
        @notice returns the sOHM index, which tracks rebase growth
        @return uint
     */
    function index() public view returns (uint256) {
        return ISCCRD(sConcord).index();
    }

    /**
        @notice trigger rebase if epoch over
     */
    function rebase() public {
        if (epoch.endTime <= uint32(block.timestamp)) {
            ISCCRD(sConcord).rebase(epoch.distribute, epoch.number);

            epoch.endTime = epoch.endTime.add32(epoch.duration);
            epoch.number++;

            if (distributor != address(0)) {
                IDistributor(distributor).distribute();
            }

            uint256 balance = contractBalance();
            uint256 staked = ISCCRD(sConcord).circulatingSupply();

            if (balance <= staked) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance.sub(staked);
            }
        }
    }

    /**
        @notice returns contract OHM holdings, including bonuses provided
        @return uint
     */
    function contractBalance() public view returns (uint256) {
        return IERC20(WAGMI).balanceOf(address(this)).add(totalBonus);
    }

    /**
        @notice provide bonus to locked staking contract
        @param _amount uint
     */
    function giveLockBonus(uint256 _amount) external {
        require(msg.sender == locker);
        totalBonus = totalBonus.add(_amount);
        IERC20(sConcord).safeTransfer(locker, _amount);
    }

    /**
        @notice reclaim bonus from locked staking contract
        @param _amount uint
     */
    function returnLockBonus(uint256 _amount) external {
        require(msg.sender == locker);
        totalBonus = totalBonus.sub(_amount);
        IERC20(sConcord).safeTransferFrom(locker, address(this), _amount);
    }

    enum CONTRACTS {
        DISTRIBUTOR,
        WARMUP,
        LOCKER
    }

    /**
        @notice sets the contract address for LP staking
        @param _contract address
     */
    function setContract(CONTRACTS _contract, address _address) external onlyPolicy {
        if (_contract == CONTRACTS.DISTRIBUTOR) {
            // 0
            distributor = _address;
        } else if (_contract == CONTRACTS.WARMUP) {
            // 1
            require(warmupContract == address(0), "Warmup cannot be set more than once");
            warmupContract = _address;
        } else if (_contract == CONTRACTS.LOCKER) {
            // 2
            require(locker == address(0), "Locker cannot be set more than once");
            locker = _address;
        }
    }

    /**
     * @notice set warmup period in epoch's numbers for new stakers
     * @param _warmupPeriod uint
     */
    function setWarmup(uint256 _warmupPeriod) external onlyPolicy {
        warmupPeriod = _warmupPeriod;
    }
}
