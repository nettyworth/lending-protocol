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
      "NWPN"
    );
    await loanReceiptLender.waitForDeployment();
    const loanReceiptLenderAddress = await loanReceiptLender.getAddress();

    console.log(
      "NettyWorth Promissory Note deployed to:",
      loanReceiptLenderAddress
    );

    const loanReceiptBorrower = await LoanReceipt.deploy(
      "NettyWorth Obligation Receipt",
      "NWOR"
    );
    await loanReceiptBorrower.waitForDeployment();
    const loanReceiptBorrowerAddress = await loanReceiptBorrower.getAddress();
    console.log(
      "NettyWorth Obligation Receipt deployed to:",
      loanReceiptBorrowerAddress
    );

    // Deploy WhiteListCollection
    const WhiteListCollection = await ethers.getContractFactory(
      "WhiteListCollection"
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
      deployer
    );
    console.log("NettyWorthProxy initialized");

    // Set proxy manager for other contracts
    const cryptoVaulttx = await cryptoVault.proposeProxyManager(
      nettyWorthProxyAddress
    );
    await cryptoVaulttx.wait();
    await cryptoVault.setProxyManager();

    const loanManagertx = await loanManager.proposeProxyManager(
      nettyWorthProxyAddress
    );
    await loanManagertx.wait();
    await loanManager.setProxyManager();

    const loanReceiptLendertx = await loanReceiptLender.proposeProxyManager(
      nettyWorthProxyAddress
    );
    await loanReceiptLendertx.wait();
    await loanReceiptLender.setProxyManager();

    const loanReceiptBorrowertx = await loanReceiptBorrower.proposeProxyManager(
      nettyWorthProxyAddress
    );
    await loanReceiptBorrowertx.wait();

    await loanReceiptBorrower.setProxyManager();
    console.log("Proxy manager set for all contracts");

    // Set Open in lender and borrower receipts contracts.
    const proposedLoanReceiptLender = await loanReceiptLender.proposeSetState(
      true
    );
    await proposedLoanReceiptLender.wait();
    await loanReceiptLender.applyProposedState();

    const proposedloanReceiptBorrower =
      await loanReceiptBorrower.proposeSetState(true);

    await proposedloanReceiptBorrower.wait();
    await loanReceiptBorrower.applyProposedState();

    // //************************************ */
    // // Verify contracts on Etherscan (only for public networks)
    // if (network.name !== 'hardhat' && network.name !== 'localhost') {
    //   console.log('Waiting for block confirmations...');
    //   // Wait for 5 blocks to be mined
    //   await ethers.provider.waitForTransaction(
    //     await cryptoVault.getAddress(),
    //     5
    //   );
    //   await ethers.provider.waitForTransaction(
    //     await loanManager.getAddress(),
    //     5
    //   );
    //   await ethers.provider.waitForTransaction(
    //     await loanReceipt.getAddress(),
    //     5
    //   );
    //   await ethers.provider.waitForTransaction(
    //     await whiteListCollection.getAddress(),
    //     5
    //   );
    //   await ethers.provider.waitForTransaction(
    //     await nettyWorthProxy.getAddress(),
    //     5
    //   );
    //   await ethers.provider.waitForTransaction(
    //     await nftExample.getAddress(),
    //     5
    //   );
    //   await ethers.provider.waitForTransaction(
    //     await nettyWorthToken.getAddress(),
    //     5
    //   );

    //   console.log('Verifying contracts on Etherscan...');

    // await hre.run("verify:verify", {
    //   address: await cryptoVault.getAddress(),
    //   contract: "contracts/CryptoVault.sol:CryptoVault",
    // });

    // await hre.run("verify:verify", {
    //   address: await loanManager.getAddress(),
    //   contract: "contracts/LoanManager.sol:LoanManager",
    // });

    // await hre.run("verify:verify", {
    //   address: await loanReceipt.getAddress(),
    //   contract: "contracts/LoanReceipt.sol:LoanReceipt",
    //   constructorArguments: ["NettyWorth Loan Receipt", "NWLR"],
    // });

    // await hre.run("verify:verify", {
    //   address: await nettyWorthProxy.getAddress(),
    //   contract: "contracts/WhiteListCollection.sol:WhiteListCollection",
    // });

    // await hre.run("verify:verify", {
    //   address: await nettyWorthProxy.getAddress(),
    //   contract: "contracts/NettyWorthProxy.sol:NettyWorthProxy",
    // });

    // await hre.run("verify:verify", {
    //   address: await nftExample.getAddress(),
    //   contract: "contracts/Examples/NFTExample.sol:NFTExample",
    //   constructorArguments: [
    //     "TestNettyWorth",
    //     "TestNettyWorth NFT",
    //     "TNFT",
    //     1000,
    //   ],
    // });

    // await hre.run("verify:verify", {
    //   address: await nettyWorthToken.getAddress(),
    //   contract: "contracts/Examples/ERC20Example.sol:NettyWorthToken",
    //   constructorArguments: [parseEther("10000")],
    // });

    //   console.log('Contracts verified on Etherscan');
    // }

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

// Starting: src/scripts/deploy.js --network sepolia
// Deploying contracts with the account: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
// Deploying to network: hardhat
// CryptoVault deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
// LoanManager deployed to: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
// NettyWorth Promissory Note deployed to: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
// NettyWorth Obligation Receipt deployed to: 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
// whiteListCollection deployed to: 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
// NettyWorthProxy deployed to: 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707
// NettyWorthProxy initialized
// Proxy manager set for all contracts
// TestNettyWorth NFT Contract deployed to: 0x3Aa5ebB10DC797CAC828524e59A333d0A371443c
// MyToken (ERC20) deployed to: 0x59b670e9fA9D0A427751Af201D676719a970857b
// Deployment completed successfully!
