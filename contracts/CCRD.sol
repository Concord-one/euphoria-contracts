// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC20Permit.sol";
import "./VaultOwned.sol";
import "./libraries/CustomSafeMath.sol";

contract CCRD is ERC20Permit, VaultOwned {
    using CustomSafeMath for uint256;

    constructor() ERC20('Concord', 'CCRD', 9) {}

    function mint(address account_, uint256 amount_) external onlyVault {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) public virtual {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) public virtual {
        uint256 decreasedAllowance_ = allowance(account_, msg.sender).sub(
            amount_,
            'ERC20: burn amount exceeds allowance'
        );

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}
