const DAI = "0xB2180448f8945C8Cc8AE9809E67D6bd27d8B2f2C";
const oldOHM = "0xC0b491daBf3709Ee5Eb79E603D73289Ca6060932";
const oldsOHM = "0x1Fecda1dE7b6951B248C0B62CaeBD5BAbedc2084";
const oldStaking = "0xC5d3318C0d74a72cD7C55bdf844e24516796BaB2";
const oldwsOHM = "0xe73384f11Bb748Aa0Bc20f7b02958DF573e6E2ad";
const sushiRouter = "0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506";
const uniRouter = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
const oldTreasury = "0x0d722D813601E48b7DAcb2DF9bae282cFd98c6E7";

const FRAX = "0x2f7249cb599139e560f0c81c269ab9b04799e453";
const LUSD = "0x45754df05aa6305114004358ecf8d04ff3b84e26";


// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const Greeter = await ethers.getContractFactory("Greeter");
  const greeter = await Greeter.deploy("Hello, Hardhat!");

  await greeter.deployed();

  console.log("Greeter deployed to:", greeter.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
