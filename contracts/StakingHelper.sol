// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./interfaces/IStaking.sol";
import "./interfaces/IERC20.sol";

contract StakingHelper {
    address public immutable staking;
    address public immutable CCRD;

    constructor(address _staking, address _CCRD) {
        require(_staking != address(0));
        staking = _staking;
        require(_CCRD != address(0));
        CCRD = _CCRD;
    }

    function stake(uint256 _amount, address recipient) external {
        IERC20(CCRD).transferFrom(msg.sender, address(this), _amount);
        IERC20(CCRD).approve(staking, _amount);
        IStaking(staking).stake(_amount, recipient);
        IStaking(staking).claim(recipient);
    }
}
