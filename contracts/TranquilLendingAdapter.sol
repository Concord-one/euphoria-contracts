// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./interfaces/ILendingAdapter.sol";
import "./interfaces/tranquil/ITqErc20.sol";
import "./interfaces/tranquil/ITranquilStaking.sol";
import "./interfaces/tranquil/ITqComptroller.sol";
import "./Policy.sol";

contract TranquilLendingAdapter is ILendingAdapter, Policy {

  mapping(IERC20 => uint) public managedAssetIndex;
  ITqErc20[] public managedAssets;
  address public treasury;

  IERC20 public tranqToken;

  ITqComptroller public lendingReward;
  ITranquilStaking public lockedTranquilReward;

  modifier onlyTreasury() {
    require(msg.sender == treasury, "only treasury");
    _;
  }

  constructor(
    address _treasury,
    IERC20 _tranqToken,
    ITqComptroller _lendingReward,
    ITranquilStaking _lockedTranquilReward
  ) {
    treasury = _treasury;
    lendingReward = _lendingReward;
    lockedTranquilReward = _lockedTranquilReward;
    tranqToken = _tranqToken;
  }

  function addManagedAsset(ITqErc20 compositeAsset) public onlyPolicy {
    uint assetIndex = managedAssetIndex[compositeAsset.underlying()];
    require(assetIndex == 0, "asset already managed");

    managedAssets.push(compositeAsset);
    managedAssetIndex[compositeAsset.underlying()] = managedAssets.length;
  }

  function removeManagedAsset(ITqErc20 compositeAsset) public onlyPolicy {
    uint assetIndex = managedAssetIndex[compositeAsset.underlying()];
    require(assetIndex != 0, "asset not managed");

    delete managedAssetIndex[compositeAsset.underlying()];
    managedAssets[assetIndex] = managedAssets[managedAssets.length - 1];
    managedAssets.pop();
  }

  function withdraw(IERC20 _underlyingAsset, uint _amount) external onlyTreasury returns (uint) {
    uint assetIndex = managedAssetIndex[_underlyingAsset];
    require(assetIndex != 0, "asset not managed");

    ITqErc20 compositeAsset = managedAssets[assetIndex - 1];

    uint errCode = compositeAsset.redeemUnderlying(_amount);

    if(errCode == 0) {
      compositeAsset.transfer(msg.sender, _amount);
    }

    return errCode;
  }

  function lend(IERC20 _underlyingAsset, uint _amount) external onlyTreasury returns (uint) {
    uint assetIndex = managedAssetIndex[_underlyingAsset];
    require(assetIndex != 0, "asset not managed");

    ITqErc20 compositeAsset = managedAssets[assetIndex - 1];

    // 1. retrieve the assets
    IERC20(compositeAsset.underlying()).transferFrom(msg.sender, address(this), _amount);

    // 2. Lend to the protocol
    compositeAsset.approve(address(this), _amount);
    return compositeAsset.mint(_amount);
  }

  function valueOf(IERC20 _underlyingAsset) external returns (uint) {
    uint assetIndex = managedAssetIndex[_underlyingAsset];
    require(assetIndex != 0, "asset not managed");

    ITqErc20 compositeAsset = managedAssets[assetIndex - 1];

    uint tokenDecimals = compositeAsset.decimals();
    uint underlyingDecimals = IERC20(compositeAsset.underlying()).decimals();
    uint exchangeRateCurrent = compositeAsset.exchangeRateCurrent();
    uint mantissa = 18 + underlyingDecimals - tokenDecimals;

    uint amount = compositeAsset.balanceOf(address(this));

    return (amount * exchangeRateCurrent) / (10 ** mantissa);
  }

  function claimRewards() external {
    // Claim the rewards from the different pools.
    lendingReward.claimReward(0, payable(address(this)));
    lockedTranquilReward.claimRewards();

    // Accrued TRANQ tokens are then pushed into the locked pool
    tranqToken.approve(address(lockedTranquilReward), tranqToken.balanceOf(address(this)));
    lockedTranquilReward.deposit(tranqToken.balanceOf(address(this)));

    // gains in other tokens are then transfered back to the treasury,
    // and recompounded the next round if needed.
    for (uint256 idx = 0; idx < managedAssets.length; idx++) {
      IERC20 asset = managedAssets[idx];
      asset.transfer(treasury, asset.balanceOf(address(this)));
    }
  }

}