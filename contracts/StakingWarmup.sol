// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./interfaces/IERC20.sol";

contract StakingWarmup {
    address public immutable staking;
    address public immutable sCCRD;

    constructor(address _staking, address _sCCRD) {
        require(_staking != address(0));
        staking = _staking;
        require(_sCCRD != address(0));
        sCCRD = _sCCRD;
    }

    function retrieve(address _staker, uint256 _amount) external {
        require(msg.sender == staking);
        IERC20(sCCRD).transfer(_staker, _amount);
    }
}
