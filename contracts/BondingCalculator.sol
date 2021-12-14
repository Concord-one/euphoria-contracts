// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.10;

import "./interfaces/IBondCalculator.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Pair.sol";

import "./libraries/FixedPoint.sol";
import "./libraries/CustomSafeMath.sol";

contract BondingCalculator is IBondCalculator {
    using FixedPoint for *;
    using CustomSafeMath for uint256;
    using CustomSafeMath for uint112;

    address public immutable WAGMI;

    constructor(address _WAGMI) {
        require(_WAGMI != address(0));
        WAGMI = _WAGMI;
    }

    function getKValue(address _pair) public view returns (uint256 k_) {
        uint256 token0 = IERC20(IUniswapV2Pair(_pair).token0()).decimals();
        uint256 token1 = IERC20(IUniswapV2Pair(_pair).token1()).decimals();
        uint256 decimals = token0.add(token1).sub(IERC20(_pair).decimals());

        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_pair).getReserves();
        k_ = reserve0.mul(reserve1).div(10**decimals);
    }

    function getTotalValue(address _pair) public view returns (uint256 _value) {
        _value = getKValue(_pair).sqrrt().mul(2);
    }

    function valuation(address _pair, uint256 amount_) external view override returns (uint256 _value) {
        uint256 totalValue = getTotalValue(_pair);
        uint256 totalSupply = IUniswapV2Pair(_pair).totalSupply();

        _value = totalValue.mul(FixedPoint.fraction(amount_, totalSupply).decode112with18()).div(1e18);
    }

    function markdown(address _pair) external view returns (uint256) {
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_pair).getReserves();

        uint256 reserve;
        if (IUniswapV2Pair(_pair).token0() == WAGMI) {
            reserve = reserve1;
        } else {
            reserve = reserve0;
        }
        return reserve.mul(2 * (10**IERC20(WAGMI).decimals())).div(getTotalValue(_pair));
    }
}
