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

    // Deploy TestToken NFT (for testing purposes)
    const NFTExample = await ethers.getContractFactory("NFTExample");
    const nftExample = await NFTExample.deploy(
      "TestNettyWorth",
      "TestNettyWorth NFT",
      "TNFT",
      1000
    );
    await nftExample.waitForDeployment();
    const nftExampleAddress = await nftExample.getAddress();

    console.log("TestNettyWorth NFT Contract deployed to:", nftExampleAddress);

    // Transfer some NFTs to borrower for testing
    await nftExample.airdrop("0xa611531661B5649688605a16ca7a245980F69A99", 100);

    // Deploy ERC20 token (for testing purposes)
    const NettyWorthToken = await ethers.getContractFactory("NettyWorthToken");
    const nettyWorthToken = await NettyWorthToken.deploy(parseEther("10000")); // 1 million initial supply
    await nettyWorthToken.waitForDeployment();
    const nettyWorthTokenAddress = await nettyWorthToken.getAddress();

    console.log("MyToken (ERC20) deployed to:", nettyWorthTokenAddress);

    // Transfer some ERC20 to lender for testing
    await nettyWorthToken.transfer(
      "0x2DC67345a60b5f2BA1d4f4bB661F6Ec31AF6B061",
      ethers.parseUnits("100000000", 18)
    );

    // Transfer some ERC20 to borrower for testing
    await nettyWorthToken.transfer(
      "0xa611531661B5649688605a16ca7a245980F69A99",
      ethers.parseUnits("100000000", 18)
    );

    // Whiteslist nft collection & erc20
    await whiteListCollection.whiteListErc20Token([
      nettyWorthTokenAddress.toString(),
    ]);
    await whiteListCollection.whiteListCollection([
      nftExampleAddress.toString(),
    ]);

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

//   Deploying contracts with the account: 0x7eEc0f63AE8d1bD9677A021BD254f654a72fd50B
// Deploying to network: sepolia
// CryptoVault deployed to: 0x482715C7aBF6d14d306E69709CD9F48F59BCe385
// LoanManager deployed to: 0x2FFC0f6e817303c343ad6faF28c3af023F20c8A6
// NettyWorth Promissory Note deployed to: 0xB557DA6EE7888F78C714134a67081B130dD35667
// NettyWorth Obligation Receipt deployed to: 0xA82385d1eF1a01A1aE4FB48AC4F600E72E651335
// whiteListCollection deployed to: 0x44E79a99B4b9cE8A8d9a9149E1cB39927FDDaf82
// NettyWorthProxy deployed to: 0x2d84690a4D90d60BD04b90ad0cdB9929f6437DEc
// NettyWorthProxy initialized
// Proxy manager set for all contracts
// TestNettyWorth NFT Contract deployed to: 0x9bc303Ca3FadEEB5760eA5ed8cAED1Ffc7d8C3f5
// MyToken (ERC20) deployed to: 0xA903eE0d8163e6054FE6aAca0D36b60565E4f4d1
// Deployment completed successfully!
