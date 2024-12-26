const { ethers } = require("hardhat");
require("dotenv").config();
 
const {
  CryptoVault_Address,
  LoanManager_Address,
  LoanReceiptLender_Address,
  LoanReceiptBorrower_Address,
  nettyWorthProxyAddress,
  WhiteListCollection_Address,
  QUICKNODE_MAINNET_URL,
  New_Admin_Multisig,
  ADMIN_PRIVATE_KEY,
} = process.env;
 
const provider = new ethers.JsonRpcProvider(QUICKNODE_MAINNET_URL);
const wallet = new ethers.Wallet(ADMIN_PRIVATE_KEY, provider);
 
const {
  abi: cryptoVaultABI,
} = require("../artifacts/src/contracts/CryptoVault.sol/CryptoVault.json");
const CryptoVault = new ethers.Contract(
  CryptoVault_Address,
  cryptoVaultABI,
  wallet
);
// console.log(CryptoVault);
 
const {
  abi: LoanManagerABI,
} = require("../artifacts/src/contracts/LoanManager.sol/LoanManager.json");
const LoanManager = new ethers.Contract(
  LoanManager_Address,
  LoanManagerABI,
  wallet
);
// console.log(LoanManager);
 
const {
  abi: LoanReceiptABILender,
} = require("../artifacts/src/contracts/LoanReceipt.sol/LoanReceipt.json");
const LoanReceiptLender = new ethers.Contract(
  LoanReceiptLender_Address,
  LoanReceiptABILender,
  wallet
);
// console.log(LoanReceiptLender);
 
const {
  abi: LoanReceiptABIBorrower,
} = require("../artifacts/src/contracts/LoanReceipt.sol/LoanReceipt.json");
const LoanReceiptBorrower = new ethers.Contract(
  LoanReceiptBorrower_Address,
  LoanReceiptABIBorrower,
  wallet
);

const {
  abi: NettProxyABI,
} = require("../artifacts/src/contracts/NettyWorthProxy.sol/NettyWorthProxy.json");
const NettyWorthProxyContract = new ethers.Contract(
  nettyWorthProxyAddress,
  NettProxyABI,
  wallet
);

async function main() {
  try {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // Log the current network
    const network = await ethers.provider.getNetwork();
    console.log("Deploying to network:", network.name);

    // Deploy CryptoVault
    // const CryptoVault = await ethers.getContractFactory("CryptoVault");
    // const cryptoVault = await CryptoVault.deploy();
    // await cryptoVault.waitForDeployment();
    // const cryptoVaultAddress = await cryptoVault.getAddress();
    // console.log("CryptoVault deployed to:", cryptoVaultAddress);

    // Deploy LoanManager
    // const LoanManager = await ethers.getContractFactory("LoanManager");
    // const loanManager = await LoanManager.deploy();
    // await loanManager.waitForDeployment();
    // const loanManagerAddress = await loanManager.getAddress();

    // console.log("LoanManager deployed to:", loanManagerAddress);

    // Deploy LoanReceipt
    // const LoanReceipt = await ethers.getContractFactory("LoanReceipt");
    // const loanReceiptLender = await LoanReceipt.deploy(
    //   "NettyWorth Promissory Note",
    //   "NWPN"
    // );
    // await loanReceiptLender.waitForDeployment();
    // const loanReceiptLenderAddress = await loanReceiptLender.getAddress();

    // console.log(
    //   "NettyWorth Promissory Note deployed to:",
    //   loanReceiptLenderAddress
    // );

    // const loanReceiptBorrower = await LoanReceipt.deploy(
    //   "NettyWorth Obligation Receipt",
    //   "NWOR"
    // );
    // await loanReceiptBorrower.waitForDeployment();
    // const loanReceiptBorrowerAddress = await loanReceiptBorrower.getAddress();
    // console.log(
    //   "NettyWorth Obligation Receipt deployed to:",
    //   loanReceiptBorrowerAddress
    // );

    // Deploy WhiteListCollection
    // const WhiteListCollection = await ethers.getContractFactory(
    //   "WhiteListCollection"
    // );
    // const whiteListCollection = await WhiteListCollection.deploy();
    // await whiteListCollection.waitForDeployment();
    // const whiteListCollectionAddress = await whiteListCollection.getAddress();
    // console.log("whiteListCollection deployed to:", whiteListCollectionAddress);

    // // Deploy NettyWorthProxy
    // const NettyWorthProxy = await ethers.getContractFactory("NettyWorthProxy");
    // const nettyWorthProxy = await NettyWorthProxy.deploy();
    // await nettyWorthProxy.waitForDeployment();
    // const nettyWorthProxyAddress = await nettyWorthProxy.getAddress();

    // console.log("NettyWorthProxy deployed to:", nettyWorthProxyAddress);

    // // Initialize NettyWorthProxy
    // await nettyWorthProxy.initialize(
    //   CryptoVault_Address,
    //   LoanManager_Address,
    //   LoanReceiptLender_Address,
    //   LoanReceiptBorrower_Address,
    //   WhiteListCollection_Address,
    //   deployer
    // );
    // console.log("NettyWorthProxy initialized");

    // Set proxy manager for other contracts
    // const cryptoVaulttx = await CryptoVault.proposeProxyManager(
    //   nettyWorthProxyAddress
    // );
    // await cryptoVaulttx.wait();
    // await CryptoVault.setProxyManager();

    // const loanManagertx = await LoanManager.proposeProxyManager(
    //   nettyWorthProxyAddress
    // );
    // await loanManagertx.wait();
    await LoanManager.setProxyManager();

    const loanReceiptLendertx = await LoanReceiptLender.proposeProxyManager(
      nettyWorthProxyAddress
    );
    await loanReceiptLendertx.wait(2);
    await LoanReceiptLender.setProxyManager();

    const loanReceiptBorrowertx = await LoanReceiptBorrower.proposeProxyManager(
      nettyWorthProxyAddress
    );
    await loanReceiptBorrowertx.wait(2);

    await LoanReceiptBorrower.setProxyManager();
    console.log("Proxy manager set for all contracts");

     // OwnerShip changed to MultiSigWallet
     const cryptoVaulttx1 = await CryptoVault.transferOwnership(
      New_Admin_Multisig
    );
    await cryptoVaulttx1.wait();

    const loanManagertx1 = await LoanManager.transferOwnership(
      New_Admin_Multisig
    );
    await loanManagertx1.wait();

    const loanReceiptLendertx1 = await LoanReceiptLender.transferOwnership(
      New_Admin_Multisig
    );
    await loanReceiptLendertx1.wait();

    const loanReceiptBorrowertx1 = await LoanReceiptBorrower.transferOwnership(
      New_Admin_Multisig
    );
    await loanReceiptBorrowertx1.wait();

    const nettyWorthProxyContracttx1 = await NettyWorthProxyContract.transferOwnership(
      New_Admin_Multisig
    );
    await nettyWorthProxyContracttx1.wait();
    
    console.log("MutliSig Ownership changed for all contracts");

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
