// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ITqComptroller {
  function claimReward(uint8 rewardType, address payable holder) external;
}