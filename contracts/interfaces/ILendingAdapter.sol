// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IERC20.sol";

interface ILendingAdapter {
  function lend(IERC20 _underlyingAsset, uint _amount) external returns (uint);
  function withdraw(IERC20 _underlyingAsset, uint _amount) external returns (uint);
  function valueOf(IERC20 _underlyingAsset) external returns (uint);
  function claimRewards() external;
}