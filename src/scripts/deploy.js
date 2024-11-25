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
    const proposedLoanReceiptLender = await loanReceiptLender.proposeSetOpen(
      true,
    );
    await proposedLoanReceiptLender.wait();
    await loanReceiptLender.setOpen();

    const proposedloanReceiptBorrower =
      await loanReceiptBorrower.proposeSetOpen(true);

    await proposedloanReceiptBorrower.wait();
    await loanReceiptBorrower.setOpen();

    // Deploy TestToken NFT (for testing purposes)
    const NFTExample = await ethers.getContractFactory("NFTExample");
    const nftExample = await NFTExample.deploy(
      "TestNettyWorth",
      "TestNettyWorth NFT",
      "TNFT",
      1000,
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
      ethers.parseUnits("100000000", 18),
    );

    // Transfer some ERC20 to borrower for testing
    await nettyWorthToken.transfer(
      "0xa611531661B5649688605a16ca7a245980F69A99",
      ethers.parseUnits("100000000", 18),
    );

    // Whiteslist nft collection & erc20
    await whiteListCollection.whiteListErc20Token([
      nettyWorthTokenAddress.toString(),
    ]);
    await whiteListCollection.whiteListCollection([
      nftExampleAddress.toString(),
    ]);

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

//   CryptoVault deployed to: 0xa2AE2F8093d446D561701AAF4E592b1077E1786a
// LoanManager deployed to: 0xdf0126E85FaC71129dC225462d023A80cc3dF258
// NettyWorth Promissory Note deployed to: 0x01cDDFBCA7b208fF2A70d6752bAe419B68e9BbC8
// NettyWorth Obligation Receipt deployed to: 0xcf829b3FACeD97ddd15503b2cfda8e346344c57D
// whiteListCollection deployed to: 0x9F94b4Db5b4B87e3f21e05e701b8391c386B6D92
// NettyWorthProxy deployed to: 0xf1aB9d2f2403f0Dd44C8fc8F0198B1E6440D6bdB
// NettyWorthProxy initialized
// Proxy manager set for all contracts
// TestNettyWorth NFT Contract deployed to: 0x2ebD68C601a5334dEcFeA1C2aB4d748467fDAC69
// MyToken (ERC20) deployed to: 0x4EA8ad3595EEBA27a0A8c5aD6AFF2226A88FB55A
