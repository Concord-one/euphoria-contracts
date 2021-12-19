// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ITranquilStaking {
  function deposit(uint amount) external;
  function redeem(uint amount) external;
  function claimRewards() external;
}