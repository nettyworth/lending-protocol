const { parseEther } = require("ethers");
const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
  try {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // Log the current network
    const network = await ethers.provider.getNetwork();
    console.log("Deploying to network:", network.name);

    // Deploy CryptoVault
    const CryptoVault = await ethers.getContractFactory("CryptoVault");
    const cryptoVault = await CryptoVault.deploy();
    await cryptoVault.waitForDeployment();
    const cryptoVaultAddress = await cryptoVault.getAddress();
    console.log("CryptoVault deployed to:", cryptoVaultAddress);

    // Deploy LoanManager
    const LoanManager = await ethers.getContractFactory("LoanManager");
    const loanManager = await LoanManager.deploy();
    await loanManager.waitForDeployment();
    const loanManagerAddress = await loanManager.getAddress();

    console.log("LoanManager deployed to:", loanManagerAddress);

    // Deploy LoanReceipt
    const LoanReceipt = await ethers.getContractFactory("LoanReceipt");
    const loanReceiptLender = await LoanReceipt.deploy(
      "NettyWorth Promissory Note",
      "NWPN",
    );
    await loanReceiptLender.waitForDeployment();
    const loanReceiptLenderAddress = await loanReceiptLender.getAddress();

    console.log(
      "NettyWorth Promissory Note deployed to:",
      loanReceiptLenderAddress,
    );

    const loanReceiptBorrower = await LoanReceipt.deploy(
      "NettyWorth Obligation Receipt",
      "NWOR",
    );
    await loanReceiptBorrower.waitForDeployment();
    const loanReceiptBorrowerAddress = await loanReceiptBorrower.getAddress();
    console.log(
      "NettyWorth Obligation Receipt deployed to:",
      loanReceiptBorrowerAddress,
    );

    // Deploy WhiteListCollection
    const WhiteListCollection = await ethers.getContractFactory(
      "WhiteListCollection",
    );
    const whiteListCollection = await WhiteListCollection.deploy();
    await whiteListCollection.waitForDeployment();
    const whiteListCollectionAddress = await whiteListCollection.getAddress();
    console.log("whiteListCollection deployed to:", whiteListCollectionAddress);

    // Deploy NettyWorthProxy
    const NettyWorthProxy = await ethers.getContractFactory("NettyWorthProxy");
    const nettyWorthProxy = await NettyWorthProxy.deploy();
    await nettyWorthProxy.waitForDeployment();
    const nettyWorthProxyAddress = await nettyWorthProxy.getAddress();

    console.log("NettyWorthProxy deployed to:", nettyWorthProxyAddress);

    // Initialize NettyWorthProxy
    await nettyWorthProxy.initialize(
      cryptoVaultAddress,
      loanManagerAddress,
      loanReceiptLenderAddress,
      loanReceiptBorrowerAddress,
      whiteListCollectionAddress,
      deployer,
    );
    console.log("NettyWorthProxy initialized");

    // Set proxy manager for other contracts
    const cryptoVaulttx = await cryptoVault.proposeProxyManager(
      nettyWorthProxyAddress,
    );
    await cryptoVaulttx.wait();
    await cryptoVault.setProxyManager();

    const loanManagertx = await loanManager.proposeProxyManager(
      nettyWorthProxyAddress,
    );
    await loanManagertx.wait();
    await loanManager.setProxyManager();

    const loanReceiptLendertx = await loanReceiptLender.proposeProxyManager(
      nettyWorthProxyAddress,
    );
    await loanReceiptLendertx.wait();
    await loanReceiptLender.setProxyManager();

    const loanReceiptBorrowertx = await loanReceiptBorrower.proposeProxyManager(
      nettyWorthProxyAddress,
    );
    await loanReceiptBorrowertx.wait();

    await loanReceiptBorrower.setProxyManager();
    console.log("Proxy manager set for all contracts");

    // Set Open in lender and borrower receipts contracts.
    const proposedLoanReceiptLender = await loanReceiptLender.proposeSetState(
      true,
    );
    await proposedLoanReceiptLender.wait();
    await loanReceiptLender.applyProposedState();

    const proposedloanReceiptBorrower =
      await loanReceiptBorrower.proposeSetState(true);

    await proposedloanReceiptBorrower.wait();
    await loanReceiptBorrower.applyProposedState();

    console.log("Deployment completed successfully!");
  } catch (error) {
    console.error("Error during deployment:", error);
    process.exit(1);
  }
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
