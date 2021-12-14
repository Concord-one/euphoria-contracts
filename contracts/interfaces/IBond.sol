// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IBond {
    function redeem(address _recipient, bool _stake) external returns (uint256);

    function pendingPayoutFor(address _depositor) external view returns (uint256 pendingPayout_);
}