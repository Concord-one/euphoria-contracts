// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IERC20.sol";

interface ILendingRewardProgram {
  function claimReward() external;
}