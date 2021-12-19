// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../IERC20.sol";

interface ITqErc20 is IERC20 {
    /*** User Interface ***/
    function underlying() external view returns (IERC20);
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);

    function exchangeRateCurrent() external returns (uint);

    // function liquidateBorrow(address borrower, uint repayAmount, TqTokenInterface tqTokenCollateral) external returns (uint);
}
