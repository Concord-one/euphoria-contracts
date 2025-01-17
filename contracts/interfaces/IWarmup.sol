// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IWarmup {
    function retrieve(address staker_, uint256 amount_) external;
}