// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.10;

import "./interfaces/IBondCalculator.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IChainlinkPriceAggregator.sol";

import "./libraries/FixedPoint.sol";
import "./libraries/CustomSafeMath.sol";

contract UniBondingCalculator is IBondCalculator {
  using FixedPoint for *;
  using CustomSafeMath for uint256;
  using CustomSafeMath for uint112;

  IChainlinkPriceAggregator public immutable aggregator;

  constructor(IChainlinkPriceAggregator _aggregator) {
    aggregator = _aggregator;
  }

  function valuation(address _token, uint256 _amount) external view override returns (uint256 _value) {
    (
      uint80 roundID,
      int price,
      uint startedAt,
      uint timeStamp,
      uint80 answeredInRound
    ) = aggregator.latestRoundData();

    return (price.mul(_amount)).div(aggregator.decimals());
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
