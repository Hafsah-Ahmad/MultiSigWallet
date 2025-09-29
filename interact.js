const hre = require("hardhat");

async function main() {
  const [deployer, owner1, owner2, owner3] = await hre.ethers.getSigners();
  const contractAddress = "YOUR_DEPLOYED_CONTRACT_ADDRESS"; // Replace

  const MultiSigWallet = await hre.ethers.getContractFactory("MultiSigWallet");
  const wallet = MultiSigWallet.attach(contractAddress);

  // Example: owner1 submits a transaction
  const to = owner3.address;
  const value = hre.ethers.parseEther("0.1");
  const data = "0x"; // empty bytes
  const expiration = 0;

  const tx = await wallet.connect(owner1).submitTransaction(to, value, data, expiration);
  await tx.wait();
  console.log("Transaction submitted by owner1");

  // Owner2 confirms
  const confirmTx = await wallet.connect(owner2).confirmTransaction(0);
  await confirmTx.wait();
  console.log("Transaction confirmed by owner2");

  // Owner1 executes
  const executeTx = await wallet.connect(owner1).executeTransaction(0);
  await executeTx.wait();
  console.log("Transaction executed!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
