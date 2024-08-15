// scripts/deploy.js

require("dotenv").config();
const { ethers } = require("hardhat");

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
    await cryptoVault.deployed();
    console.log("CryptoVault deployed to:", cryptoVault.address);

    // Deploy LoanManager
    const LoanManager = await ethers.getContractFactory("LoanManager");
    const loanManager = await LoanManager.deploy();
    await loanManager.deployed();
    console.log("LoanManager deployed to:", loanManager.address);

    // Deploy LoanReceipt
    const LoanReceipt = await ethers.getContractFactory("LoanReceipt");
    const loanReceipt = await LoanReceipt.deploy("NettyWorth Loan Receipt", "NWLR");
    await loanReceipt.deployed();
    console.log("LoanReceipt deployed to:", loanReceipt.address);

    // Deploy NettyWorthProxy
    const NettyWorthProxy = await ethers.getContractFactory("NettyWorthProxy");
    const nettyWorthProxy = await NettyWorthProxy.deploy();
    await nettyWorthProxy.deployed();
    console.log("NettyWorthProxy deployed to:", nettyWorthProxy.address);

    // Initialize NettyWorthProxy
    await nettyWorthProxy.initialize(cryptoVault.address, loanManager.address, loanReceipt.address);
    console.log("NettyWorthProxy initialized");

    // Set proxy manager for other contracts
    await cryptoVault.setProxyManager(nettyWorthProxy.address);
    await loanManager.setProxyManager(nettyWorthProxy.address);
    await loanReceipt.setProxyManager(nettyWorthProxy.address);
    console.log("Proxy manager set for all contracts");

    // Deploy TestToken (for testing purposes)
    const TestToken = await ethers.getContractFactory("TestToken");
    const testToken = await TestToken.deploy("TestProject", "Test NFT", "TNFT", 1000);
    await testToken.deployed();
    console.log("TestToken deployed to:", testToken.address);

    // Deploy ERC20 token (for testing purposes)
    const MyToken = await ethers.getContractFactory("MyToken");
    const myToken = await MyToken.deploy(1000000); // 1 million initial supply
    await myToken.deployed();
    console.log("MyToken (ERC20) deployed to:", myToken.address);

    // Verify contracts on Etherscan (only for public networks)
    if (network.name !== "hardhat" && network.name !== "localhost") {
      console.log("Waiting for block confirmations...");
      await cryptoVault.deployTransaction.wait(5);
      await loanManager.deployTransaction.wait(5);
      await loanReceipt.deployTransaction.wait(5);
      await nettyWorthProxy.deployTransaction.wait(5);
      await testToken.deployTransaction.wait(5);
      await myToken.deployTransaction.wait(5);

      console.log("Verifying contracts on Etherscan...");
      
      await hre.run("verify:verify", {
        address: cryptoVault.address,
        contract: "contracts/CryptoVault.sol:CryptoVault",
      });

      await hre.run("verify:verify", {
        address: loanManager.address,
        contract: "contracts/LoanManager.sol:LoanManager",
      });

      await hre.run("verify:verify", {
        address: loanReceipt.address,
        contract: "contracts/LoanReceipt.sol:LoanReceipt",
        constructorArguments: ["NettyWorth Loan Receipt", "NWLR"],
      });

      await hre.run("verify:verify", {
        address: nettyWorthProxy.address,
        contract: "contracts/NettyWorthProxy.sol:NettyWorthProxy",
      });

      await hre.run("verify:verify", {
        address: testToken.address,
        contract: "contracts/TestToken.sol:TestToken",
        constructorArguments: ["TestProject", "Test NFT", "TNFT", 1000],
      });

      await hre.run("verify:verify", {
        address: myToken.address,
        contract: "contracts/ERC20Example.sol:MyToken",
        constructorArguments: [1000000],
      });

      console.log("Contracts verified on Etherscan");
    }

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