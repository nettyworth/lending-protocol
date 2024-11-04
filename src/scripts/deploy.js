const { parseEther } = require('ethers');
const { ethers } = require('hardhat');
require('dotenv').config();

// console.log(process.env.LENDER_PRIVATE_KEY);

// const lender = new ethers.Wallet(process.env.LENDER_PRIVATE_KEY);
// const borrower = new ethers.Wallet(process.env.BORROWER_PRIVATE_KEY);
// const provider = new ethers.JsonRpcProvider(process.env.QUICKNODE_SEPOLIA_URL);
// const lenderSigner = lender.connect(provider);
// const borrowerSigner = borrower.connect(provider);

// console.log(lenderSigner);
// console.log(borrowerSigner);

async function main() {
  try {
    const [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account:', deployer.address);

    // const lender = ethers.Wallet(process.env.LENDER_PRIVATE_KEY);
    // const borrower = ethers.Wallet(process.env.BORROWER_PRIVATE_KEY);

    // Log the current network
    const network = await ethers.provider.getNetwork();
    console.log('Deploying to network:', network.name);

    // Deploy CryptoVault
    const CryptoVault = await ethers.getContractFactory('CryptoVault');
    const cryptoVault = await CryptoVault.deploy();
    await cryptoVault.waitForDeployment();
    console.log('CryptoVault deployed to:', await cryptoVault.getAddress());

    // Deploy LoanManager
    const LoanManager = await ethers.getContractFactory('LoanManager');
    const loanManager = await LoanManager.deploy();
    await loanManager.waitForDeployment();
    console.log('LoanManager deployed to:', await loanManager.getAddress());

    // Deploy LoanReceipt
    const LoanReceipt = await ethers.getContractFactory('LoanReceipt');
    const loanReceiptLender = await LoanReceipt.deploy(
      'NettyWorth Promissory Note',
      'PNNW'
    );
    await loanReceiptLender.waitForDeployment();
    console.log(
      'NettyWorth Promissory Note deployed to:',
      await loanReceiptLender.getAddress()
    );

    const loanReceiptBorrower = await LoanReceipt.deploy(
      'NettyWorth Obligation Receipt',
      'ORNW'
    );
    await loanReceiptBorrower.waitForDeployment();
    console.log(
      'NettyWorth Obligation Receipt deployed to:',
      await loanReceiptBorrower.getAddress()
    );

    const WhiteListCollection = await ethers.getContractFactory(
      'WhiteListCollection'
    );
    const whiteListCollection = await WhiteListCollection.deploy();
    await whiteListCollection.waitForDeployment();
    console.log(
      'whiteListCollection deployed to:',
      await whiteListCollection.getAddress()
    );

    // Deploy NettyWorthProxy
    const NettyWorthProxy = await ethers.getContractFactory('NettyWorthProxy');
    const nettyWorthProxy = await NettyWorthProxy.deploy();
    await nettyWorthProxy.waitForDeployment();
    console.log(
      'NettyWorthProxy deployed to:',
      await nettyWorthProxy.getAddress()
    );

    // Initialize NettyWorthProxy
    await nettyWorthProxy.initialize(
      await cryptoVault.getAddress(),
      await loanManager.getAddress(),
      await loanReceiptLender.getAddress(),
      await loanReceiptBorrower.getAddress(),
      await whiteListCollection.getAddress(),
      deployer
    );
    console.log('NettyWorthProxy initialized');

    // Set proxy manager for other contracts

    await cryptoVault.proposeProxyManager(await nettyWorthProxy.getAddress());
    await cryptoVault.setProxyManager();
    await loanManager.proposeProxyManager(await nettyWorthProxy.getAddress());
    await loanManager.setProxyManager();
    await loanReceiptLender.proposeProxyManager(
      await nettyWorthProxy.getAddress()
    );
    await loanReceiptLender.setProxyManager();
    await loanReceiptBorrower.proposeProxyManager(
      await nettyWorthProxy.getAddress()
    );
    await loanReceiptBorrower.setProxyManager();
    console.log('Proxy manager set for all contracts');

    await loanReceiptLender.proposeSetOpen(true);
    await loanReceiptLender.setOpen();
    await loanReceiptBorrower.proposeSetOpen(true);
    await loanReceiptBorrower.setOpen();
    // Deploy TestToken (for testing purposes)
    const NFTExample = await ethers.getContractFactory('NFTExample');
    const nftExample = await NFTExample.deploy(
      'TestNettyWorth',
      'TestNettyWorth NFT',
      'TNFT',
      1000
    );
    await nftExample.waitForDeployment();
    console.log(
      'TestNettyWorth NFT Contract deployed to:',
      await nftExample.getAddress()
    );

    await nftExample.airdrop('0xa611531661B5649688605a16ca7a245980F69A99', 100);

    // Deploy ERC20 token (for testing purposes)
    const NettyWorthToken = await ethers.getContractFactory('NettyWorthToken');
    const nettyWorthToken = await NettyWorthToken.deploy(parseEther('10000')); // 1 million initial supply
    await nettyWorthToken.waitForDeployment();
    console.log(
      'MyToken (ERC20) deployed to:',
      await nettyWorthToken.getAddress()
    );
    const tokenAddress = await nettyWorthToken.getAddress();
    const nftAddress = await nftExample.getAddress();

    //************************************/
    await nettyWorthToken.transfer(
      '0x2DC67345a60b5f2BA1d4f4bB661F6Ec31AF6B061',
      ethers.parseUnits('100000000', 18)
    );

    await nettyWorthToken.transfer(
      '0xa611531661B5649688605a16ca7a245980F69A99',
      ethers.parseUnits('100000000', 18)
    );

    await whiteListCollection.whiteListErc20Token([tokenAddress.toString()]);
    await whiteListCollection.whiteListCollection([nftAddress.toString()]);

    // await nettyWorthToken
    //   .connect('')
    //   .approve(await cryptoVault.getAddress(), parseEther('10000'));
    // await nftExample
    //   .connect('0xa611531661B5649688605a16ca7a245980F69A99')
    //   .setApprovalForAll(await cryptoVault.getAddress(), true);

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

    console.log('Deployment completed successfully!');
  } catch (error) {
    console.error('Error during deployment:', error);
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
