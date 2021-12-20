// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IBondCalculator {

    // Return the valuation for this kind of bond.
    // For LP, using 2 * SQRT(t1 * t2) is conservative and
    // recommended as price might fluctuate. This would protect LP bonds to
    // fluctuate in relation to the prices, as t1 * t2 is constant over the life of the pool.
    //
    // => For stable token, use of oracle.
    function valuation(address _token, uint _amount) external view returns (uint);

    // In LP, Represent the necessary multiplicator for concord amount in LP
    // to reach balance of 1 USD = 1 CONCORD.
    // For example, in the case of current pair total assets of [1000 USD, 10 CCRD], the multiplicator
    // would be 10, as it would need roughly 10 times more concord injected to have 1 concord = 1 usd.
    // (and the LP assets would be [100 USD, 100 CCRD] and value = USD 200)
    // Note: Beware that value must be set in USD. In case of non-stablecoin pair, e.g. ONE-CCRD
    // This is used only on liquidty type bonds.
    function markdown(address _token) external view returns (uint);
}
