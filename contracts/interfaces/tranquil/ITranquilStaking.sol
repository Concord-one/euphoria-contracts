interface ITranquilStaking {
  function deposit(uint amount) external;
  function redeem(uint amount) external;
  function claimRewards() external;
}