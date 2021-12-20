// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.10;

import "./interfaces/IBondCalculator.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IChainlinkPriceAggregator.sol";

import "./libraries/FixedPoint.sol";
import "./libraries/CustomSafeMath.sol";

/**
Chainlink resources:

MAINNET

AAVE-USD: 0x6EE1EfCCe688D5B79CB8a400870AF471c5282992
BTC-USD: 0x3C41439Eb1bF3BA3b2C3f8C921088b267f8d11f4
ETH-USD: 0xbaf7C8149D586055ed02c286367A41E0aDA96b7C
LINK-USD: 0xD54F119D10901b4509610eA259A63169647800C4
ONE-USD: 0xdCD81FbbD6c4572A69a534D8b8152c562dA8AbEF
USDC-USD: 0xA45A41be2D8419B60A6CE2Bc393A0B086b8B3bda
USDT-USD: 0x5CaAeBE5C69a8287bffB9d00b5231bf7254145bf
UST-USD: 0xEF9ab2298715631dE7E8F17482ce63A108158819

TESTNET

DAI-USD: 0x1FA508EB3Ac431f3a9e3958f2623358e07D50fe0
ETH-USD: 0x4f11696cE92D78165E1F8A9a4192444087a45b64
DSLA-USD: 0x5f0423B1a6935dc5596e7A24d98532b67A0AeFd8
USDC-USD: 0x6F2bD4158F771E120d3692C45Eb482C16f067dec
SUSHI-USD: 0x90142a6930ecF80F1d14943224C56CFe0CD0d347
USDT-USD: 0x9A37E1abFC430B9f5E204CA9294809c1AF37F697
WBTC-USD: 0xEF637736B220a58C661bfF4b71e03ca898DCC0Bd
BUSD-USD: 0xa0ABAcC3162430b67Aa6C135dfAA08E117A38bF0
ONE-USD: 0xcEe686F89bc0dABAd95AEAAC980aE1d97A075FAD
LINK-USD: 0xcd11Ac8C18f3423c7a9C9d5784B580079A75E69a

 */
contract ChainlinkBondingCalculator is IBondCalculator {
  using FixedPoint for *;
  using CustomSafeMath for uint;
  using CustomSafeMath for uint112;

  IChainlinkPriceAggregator public immutable aggregator;

  constructor(IChainlinkPriceAggregator _aggregator) {
    aggregator = _aggregator;
  }

  function valuation(address _token, uint _amount) external view override returns (uint _value) {
    (
      /*uint80 roundID*/,
      int price,
      /*uint startedAt*/,
      /*uint timeStamp*/,
      /*uint80 answeredInRound*/
    ) = aggregator.latestRoundData();

    require(price > 0, "invalid price");
    return (uint(price).mul(_amount) * (10 ** IERC20(_token).decimals())).div( 10 ** aggregator.decimals());
  }

  // Ensure we don't use it for liquidity type of bonds.
  function markdown(address _pair) external pure returns (uint) {
    require(false, "bonding calculator not compatible");
  }
}
