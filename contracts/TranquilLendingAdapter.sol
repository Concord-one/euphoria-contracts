import "./interfaces/ILendingAdapter.sol";

contract TranquilLendingAdapter is ILendingAdapter {
  constructor(address coreAddress_) {

  }

  function lend(IERC20 _asset, uint _amount) external {
    address onBehalf = msg.sender;
  }

  function retrieve(IERC20 _asset, uint _amount) external {
    address onBehalf = msg.sender;
  }

}