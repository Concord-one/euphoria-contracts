// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IManageable {
    function policy() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}