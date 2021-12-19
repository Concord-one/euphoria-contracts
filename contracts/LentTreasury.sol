// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Policy.sol";

import "./libraries/CustomSafeMath.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/ILendingAdapter.sol";

import "./Treasury.sol";

/**
 * Treasury being able to be lent through third-party protocols (currently Tranquil)
 */
contract LentTreasury is Policy, Treasury {
  using CustomSafeMath for uint256;

  uint public constant EPSILON = 1_000; // Minimum of amount for a specific asset to rebalance the lent treasury.

  // Reward to the caller of the contract to keep rebalancing the treasury.
  // 500 gwei per blocks, as long as we have ONEs in treasury to cover the contract.
  // 500 gwei per block = 20 gas per block at 25gwei/gas
  uint public rewardPerBlock = 500 gwei;

  // Info for creating new bonds
  struct LentEntry {
    ILendingAdapter adapter;
    uint16 treasuryPercent; // between 1 and 10_000
  }

  // Used internally
  struct MemoizedLentAmount {
    ILendingAdapter adapter;
    uint16 wantedPercent;
    uint amount;
  }

  mapping(IERC20 => LentEntry[]) public adapterMap;
  uint public lastRewardBlock;

  ILendingAdapter[] public adapterList;
  mapping(ILendingAdapter => uint16) public adapterIndexes;

  constructor(
    address _CCRD,
    address _DAI,
    uint32 _secondsNeededForQueue
  ) Treasury(_CCRD, _DAI, _secondsNeededForQueue) {
    lastRewardBlock = block.number;
    rewardPerBlock = 500 gwei;
  }

  function setRewardPerBlock(uint _amount) public onlyPolicy {
    rewardPerBlock = _amount;
  }

  function addLentEntry(
    IERC20 _underlyingAsset, ILendingAdapter _adapter, uint16 _treasuryPercent
  ) public onlyPolicy {
    require(address(_underlyingAsset) != address(0), "underlying null");
    require(address(_adapter) != address(0), "lent asset null");
    require(_treasuryPercent <= 10_000, "invalid treasury percent rate");

    LentEntry memory lentEntry = LentEntry(
      _adapter, _treasuryPercent
    );
    adapterMap[_underlyingAsset].push(lentEntry);

    if(adapterIndexes[_adapter] == 0) {
      adapterList.push(_adapter);
      adapterIndexes[_adapter] = uint16(adapterList.length);
    }
  }

  // Change the ratio given to this lending strategy.
  function updateLentRatio(
    IERC20 _underlyingAsset, ILendingAdapter _adapter, uint16 treasuryPercent
  ) public onlyPolicy {
    require(address(_underlyingAsset) != address(0), "underlying null");
    require(address(_adapter) != address(0), "lent asset null");
    require(treasuryPercent <= 10_000, "invalid treasury percent rate");

    LentEntry[] storage lentEntries = adapterMap[_underlyingAsset];
    for(uint i = 0; i < lentEntries.length; i++) {
      if(lentEntries[i].adapter == _adapter) {
        lentEntries[i].treasuryPercent = treasuryPercent;
        break;
      }
    }
  }

  /**
   * Lent or remove assets based on the current ratio.
   */
  function rebalanceLentAssets() external {
    _claimRewards();
    _rebalanceLentAssets();
    _payRewardToCaller();
  }


  function _claimRewards() internal {
    for(uint i = 0; i < adapterList.length; i++) {
      adapterList[i].claimRewards();
    }
  }

  function _rebalanceLentAssets() internal {
    for (uint i = 0; i < reserveTokens.length; i++) {
      IERC20 token = IERC20(reserveTokens[i]);

      if(isReserveToken[address(token)]) {
        LentEntry[] memory lentEntries = adapterMap[token];

        uint totalAmount = valueOfToken(address(token), token.balanceOf(address(this)));

        MemoizedLentAmount[] memory memo = new MemoizedLentAmount[](lentEntries.length);

        // 1. count the total value in USD for a specific token.
        for(uint j = 0; j < lentEntries.length; j++) {
          ILendingAdapter adapter = lentEntries[j].adapter;

          uint amount = adapter.valueOf(token);
          memo[j] = MemoizedLentAmount(adapter, lentEntries[j].treasuryPercent, amount);
          totalAmount += amount;
        }

        // 1. rebalance if needed.
        for(uint j = 0; j < memo.length; j++) {
          MemoizedLentAmount memory mem = memo[j];
          ILendingAdapter adapter = mem.adapter;

          // What do we expect to lend to this adapter?
          uint expectedLent = totalAmount.mul(mem.wantedPercent).div(10_000);

          // Currently lent value.
          uint lent = mem.amount;

          uint amount = absDiff(lent, expectedLent);

          if(amount >= EPSILON) {
            if(lent < expectedLent) {
              token.approve(address(adapter), amount);
              // Lend more.
              adapter.lend(token, amount);
            } else {
              // Withdraw some token.
              adapter.withdraw(token, amount);
            }
          }
        }
      }
    }
  }

  function getCallerReward() public view returns (uint) {
    uint balance = address(this).balance;
    uint reward = (lastRewardBlock - block.number) * rewardPerBlock;
    return balance > reward ? reward : balance;
  }

  // Reward caller of the contract to keep the protocol
  // up to date.
  function _payRewardToCaller() internal {
    uint oneAmount = address(this).balance;
    uint reward = getCallerReward();

    if(oneAmount >= reward) {
      // change state before call, avoiding reentrant exploit.
      lastRewardBlock = block.number;
      payable(msg.sender).transfer(reward);
    }
  }

  function absDiff(uint a, uint b) internal pure returns (uint) {
    return a > b ? a - b : b - a;
  }

}