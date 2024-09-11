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
    await cryptoVault.waitForDeployment();
    console.log("CryptoVault deployed to:", await cryptoVault.getAddress());

    // Deploy LoanManager
    const LoanManager = await ethers.getContractFactory("LoanManager");
    const loanManager = await LoanManager.deploy();
    await loanManager.waitForDeployment();
    console.log("LoanManager deployed to:", await loanManager.getAddress());

    // Deploy LoanReceipt
    const LoanReceipt = await ethers.getContractFactory("LoanReceipt");
    const loanReceipt = await LoanReceipt.deploy(
      "NettyWorth Loan Receipt",
      "NWLR"
    );
    await loanReceipt.waitForDeployment();
    console.log("LoanReceipt deployed to:", await loanReceipt.getAddress());

    const WhiteListCollection = await ethers.getContractFactory(
      "WhiteListCollection"
    );
    const whiteListCollection = await WhiteListCollection.deploy();
    await whiteListCollection.waitForDeployment();
    console.log(
      "whiteListCollection deployed to:",
      await whiteListCollection.getAddress()
    );

    // Deploy NettyWorthProxy
    const NettyWorthProxy = await ethers.getContractFactory("NettyWorthProxy");
    const nettyWorthProxy = await NettyWorthProxy.deploy();
    await nettyWorthProxy.waitForDeployment();
    console.log(
      "NettyWorthProxy deployed to:",
      await nettyWorthProxy.getAddress()
    );

    // Initialize NettyWorthProxy
    await nettyWorthProxy.initialize(
      await cryptoVault.getAddress(),
      await loanManager.getAddress(),
      await loanReceipt.getAddress(),
      await whiteListCollection.getAddress()
    );
    console.log("NettyWorthProxy initialized");

    // Set proxy manager for other contracts
    await cryptoVault.setProxyManager(await nettyWorthProxy.getAddress());
    await loanManager.setProxyManager(await nettyWorthProxy.getAddress());
    await loanReceipt.setProxyManager(await nettyWorthProxy.getAddress());
    console.log("Proxy manager set for all contracts");

    // Deploy TestToken (for testing purposes)
    const NFTExample = await ethers.getContractFactory("NFTExample");
    const nftExample = await NFTExample.deploy(
      "TestNettyWorth",
      "TestNettyWorth NFT",
      "TNFT",
      1000
    );
    await nftExample.waitForDeployment();
    console.log(
      "TestNettyWorth NFT Contract deployed to:",
      await nftExample.getAddress()
    );

    // Deploy ERC20 token (for testing purposes)
    const NettyWorthToken = await ethers.getContractFactory("NettyWorthToken");
    const nettyWorthToken = await NettyWorthToken.deploy(
      ethers.utils.parseEther("10000")
    ); // 1 million initial supply
    await nettyWorthToken.waitForDeployment();
    console.log(
      "MyToken (ERC20) deployed to:",
      await nettyWorthToken.getAddress()
    );

    //  await NettyWorthToken.setProxyManager(await nettyWorthProxy.getAddress());
    // await loanReceipt.setProxyManager(await nettyWorthProxy.getAddress());

    // Verify contracts on Etherscan (only for public networks)
    if (network.name !== "hardhat" && network.name !== "localhost") {
      console.log("Waiting for block confirmations...");
      // Wait for 5 blocks to be mined
      await ethers.provider.waitForTransaction(
        await cryptoVault.getAddress(),
        5
      );
      await ethers.provider.waitForTransaction(
        await loanManager.getAddress(),
        5
      );
      await ethers.provider.waitForTransaction(
        await loanReceipt.getAddress(),
        5
      );
      await ethers.provider.waitForTransaction(
        await whiteListCollection.getAddress(),
        5
      );
      await ethers.provider.waitForTransaction(
        await nettyWorthProxy.getAddress(),
        5
      );
      await ethers.provider.waitForTransaction(
        await nftExample.getAddress(),
        5
      );
      await ethers.provider.waitForTransaction(
        await nettyWorthToken.getAddress(),
        5
      );

      console.log("Verifying contracts on Etherscan...");

      await hre.run("verify:verify", {
        address: await cryptoVault.getAddress(),
        contract: "contracts/CryptoVault.sol:CryptoVault",
      });

      await hre.run("verify:verify", {
        address: await loanManager.getAddress(),
        contract: "contracts/LoanManager.sol:LoanManager",
      });

      await hre.run("verify:verify", {
        address: await loanReceipt.getAddress(),
        contract: "contracts/LoanReceipt.sol:LoanReceipt",
        constructorArguments: ["NettyWorth Loan Receipt", "NWLR"],
      });

      await hre.run("verify:verify", {
        address: await nettyWorthProxy.getAddress(),
        contract: "contracts/WhiteListCollection.sol:WhiteListCollection",
      });

      await hre.run("verify:verify", {
        address: await nettyWorthProxy.getAddress(),
        contract: "contracts/NettyWorthProxy.sol:NettyWorthProxy",
      });

      await hre.run("verify:verify", {
        address: await nftExample.getAddress(),
        contract: "contracts/Examples/NFTExample.sol:NFTExample",
        constructorArguments: [
          "TestNettyWorth",
          "TestNettyWorth NFT",
          "TNFT",
          1000,
        ],
      });

      await hre.run("verify:verify", {
        address: await nettyWorthToken.getAddress(),
        contract: "contracts/Examples/ERC20Example.sol:NettyWorthToken",
        constructorArguments: [ethers.utils.parseEther("10000")],
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
