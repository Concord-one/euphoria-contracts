// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IERC20.sol";

interface ILendingAdapter {
  function lend(IERC20 _asset, uint _amount) external;
  function retrieve(IERC20 _asset, uint _amount) external;
}