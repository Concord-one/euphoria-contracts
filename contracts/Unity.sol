// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC20.sol";

import "./libraries/SafeERC20.sol";

import "./interfaces/ISCCRD.sol";

contract Unity is ERC20 {
    using SafeERC20 for ERC20;
    using Address for address;
    using SafeMath for uint256;

    address public immutable sConcord;

    constructor(address _sConcord) ERC20("Concord Unity Token", "UNITY", 9) {
        require(_sConcord != address(0));
        sConcord = _sConcord;
    }

    /**
        @notice wrap sConcord
        @param _amount uint
        @return uint
     */
    function wrap(uint256 _amount) external returns (uint256) {
        IERC20(sConcord).transferFrom(msg.sender, address(this), _amount);

        uint256 value = sConcordToUnity(_amount);
        _mint(msg.sender, value);
        return value;
    }

    /**
        @notice unwrap sConcord
        @param _amount uint
        @return uint
     */
    function unwrap(uint256 _amount) external returns (uint256) {
        _burn(msg.sender, _amount);

        uint256 value = UnityToSCCRD(_amount);
        IERC20(sConcord).transfer(msg.sender, value);
        return value;
    }

    /**
        @notice converts Unity amount to sConcord
        @param _amount uint
        @return uint
     */
    function UnityToSCCRD(uint256 _amount) public view returns (uint256) {
        return _amount.mul(ISCCRD(sConcord).index()).div(10**decimals());
    }

    /**
        @notice converts sConcord amount to Unity
        @param _amount uint
        @return uint
     */
    function sConcordToUnity(uint256 _amount) public view returns (uint256) {
        return _amount.mul(10**decimals()).div(ISCCRD(sConcord).index());
    }
}
