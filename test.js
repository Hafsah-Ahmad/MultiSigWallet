const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MultiSigWallet", function () {
  let MultiSigWallet, wallet, owner1, owner2, owner3, recipient;

  beforeEach(async function () {
    [deployer, owner1, owner2, owner3, recipient] = await ethers.getSigners();

    MultiSigWallet = await ethers.getContractFactory("MultiSigWallet");

    wallet = await MultiSigWallet.deploy(
      [owner1.address, owner2.address, owner3.address],
      2, // confirmations required
      60, // timelock
      ethers.parseEther("1") // daily limit
    );
  });

  it("should deploy with correct owners and requirements", async function () {
    expect(await wallet.numConfirmationsRequired()).to.equal(2);
  });

  it("should allow submitting and confirming a transaction", async function () {
    // fund wallet
    await deployer.sendTransaction({
      to: await wallet.getAddress(),
      value: ethers.parseEther("1"),
    });

    // submit tx
    const tx = await wallet.connect(owner1).submitTransaction(
      recipient.address,
      ethers.parseEther("0.5"),
      "0x",
      0
    );
    await tx.wait();

    // confirm
    await wallet.connect(owner2).confirmTransaction(0);

    // execute
    const execTx = await wallet.connect(owner1).executeTransaction(0);
    await execTx.wait();

    expect(await ethers.provider.getBalance(recipient.address)).to.be.gt(0);
  });
});
