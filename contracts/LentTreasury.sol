// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Policy.sol";

import "./libraries/CustomSafeMath.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/ILendingStrategy.sol";
import "./interfaces/ILendingAdapter.sol";

/**
 * Treasury being able to be lent through third-party protocols (currently Tranquil)
 */
abstract contract LentTreasury is Policy {
  using CustomSafeMath for uint256;

  // Info for creating new bonds
  struct LentEntry {
      IERC20 underlyingAsset;
      IERC20 lentAsset;
      ILendingAdapter adapter;
      uint32 borrowRate; // In 1 / 10_000, between 0 and 1.
  }

  uint public constant EPSILON = 1_000; // Minimum of amount for a specific asset to rebalance the lent treasury.
  uint public constant REWARD_PER_BLOCK = 1_000_000 wei; // Reward to the caller of the contract to keep protocol healthy. 1 gwei per 1000 blocks (each 2000s), if we have ones in the contract.

  LentEntry[] public lentRules; // Push only, beware false-positives. Only for viewing.
  mapping(address => LentEntry) public lentUnderlyingAssets;
  mapping(address => LentEntry) public lentAssets;

  ILendingRewardProgram[] public rewardPrograms;
  uint public lastRewardBlock;

  constructor() {
    lastRewardBlock = block.number;
  }

  function addLentEntry(
    address underlyingAsset,
    address lentAsset,
    address adapter,
    uint32 borrowRate
  ) external onlyPolicy {
    require(underlyingAsset != address(0), "underlying null");
    require(lentAsset != address(0), "lent asset null");
    require(adapter != address(0), "adapter null");
    require(borrowRate < 10_000, "invalid burrow rate");
    require(address(lentUnderlyingAssets[underlyingAsset].underlyingAsset) == address(0), "cannot add twice");
    require(address(lentAssets[lentAsset].lentAsset) == address(0), "cannot add twice");

    LentEntry memory lentEntry = LentEntry(
      IERC20(underlyingAsset), IERC20(lentAsset), ILendingAdapter(adapter), borrowRate
    );

    lentRules.push(lentEntry);
    lentUnderlyingAssets[underlyingAsset] = lentEntry;
    lentAssets[lentAsset] = lentEntry;
  }

  /**
   * Lent or remove assets based on the current ratio.
   */
  function rebalanceLentAssets() external {
    for (uint256 i = 0; i < rewardPrograms.length; i++) {
      rewardPrograms[i].claimReward();
    }

    for (uint256 i = 0; i < lentRules.length; i++) {
      this.rebalanceLentAsset(address(lentRules[i].underlyingAsset));
    }

    _payRewardToCaller();
  }

  function rebalanceLentAsset(address underlyingAsset) external {
    LentEntry memory lentRule = lentUnderlyingAssets[underlyingAsset];

    uint balanceUnderlying = lentRule.underlyingAsset.balanceOf(address(this));
    uint balanceLent = lentRule.lentAsset.balanceOf(address(this));

    uint wantedLent = balanceUnderlying.mul(lentRule.borrowRate).div(10_000);

    uint delta = absDiff(balanceLent, wantedLent);

    if(delta > EPSILON) {
      if(balanceLent > wantedLent) {
        lentRule.adapter.retrieve(lentRule.lentAsset, balanceLent - wantedLent);
      } else {
        uint amount = wantedLent - balanceLent;
        IERC20(lentRule.underlyingAsset).approve(address(lentRule.adapter), amount);
        lentRule.adapter.lend(
          lentRule.underlyingAsset, wantedLent - balanceLent
        );
      }
    }
  }

  function getCallerReward() public view returns (uint) {
    return (lastRewardBlock - block.number) * REWARD_PER_BLOCK;
  }

  function _payRewardToCaller() internal {
    uint oneAmount = address(this).balance;
    uint reward = getCallerReward();
    if(oneAmount >= reward) {
      // change state before, avoiding reentrant exploit.
      lastRewardBlock = block.number;
      payable(msg.sender).transfer(reward);
    }
  }

  function absDiff(uint a, uint b) internal pure returns (uint) {
    return a > b ? a - b : b - a;
  }

}