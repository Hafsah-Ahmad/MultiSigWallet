const hre = require("hardhat");

async function main() {
  const [deployer, owner1, owner2, owner3] = await hre.ethers.getSigners();

  console.log("Deploying contracts with account:", deployer.address);

  const MultiSigWallet = await hre.ethers.getContractFactory("MultiSigWallet");

  // constructor params
  const owners = [owner1.address, owner2.address, owner3.address];
  const numConfirmationsRequired = 2;
  const timeLock = 60; // 60 seconds
  const dailyLimit = hre.ethers.parseEther("1"); // 1 ETH

  const wallet = await MultiSigWallet.deploy(
    owners,
    numConfirmationsRequired,
    timeLock,
    dailyLimit
  );

  await wallet.waitForDeployment();

  console.log("MultiSigWallet deployed to:", wallet.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
