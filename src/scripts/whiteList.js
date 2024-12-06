const { ethers } = require("ethers");
require("dotenv").config();

const {
  WHITELIST_COLLECTION_ADDRESS,
  ADMIN_PRIVATE_KEY,
  QUICKNODE_SEPOLIA_URL,
} = process.env;

const {
  abi: WhiteListCollectionAbi,
} = require("../artifacts/src/contracts/WhiteListCollection.sol/WhiteListCollection.json");

const provider = new ethers.JsonRpcProvider(QUICKNODE_SEPOLIA_URL);
const admin = new ethers.Wallet(ADMIN_PRIVATE_KEY, provider);

const whiteListCollection = new ethers.Contract(
  WHITELIST_COLLECTION_ADDRESS,
  WhiteListCollectionAbi,
  admin,
);

async function WhiteList_ERC20(whiteListERC20Addresses) {
  try {
    const tx = await whiteListCollection.whiteListErc20Token(
      whiteListERC20Addresses,
    );
    console.log("Transaction submitted:", tx.hash);

    const receipt = await tx.wait();
    console.log("Transaction mined if status is '1':", receipt.status);
  } catch (error) {
    console.error("whitelist ERC20 Error:", error.message);
  }
}

async function WhiteList_Collection(whiteListCollectionAddresses) {
  try {
    const tx = await whiteListCollection.whiteListCollection(
      whiteListCollectionAddresses,
    );
    console.log("Transaction submitted ::", tx.hash);

    const receipt = await tx.wait();
    console.log("Transaction mined if status is '1':", receipt.status);
  } catch (error) {
    console.error("whitelistCollection Error:", error.message);
  }
}

const main = async () => {
  const erc20Addresses = [
    "0x1234567890abcdef1234567890abcdef12345678",
    "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd",
  ];

  const collectionAddresses = [
    "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd",
    "0x1234567890abcdef1234567890abcdef12345678",
  ];

  console.log("Starting whitelist process...");
  await WhiteList_Collection(collectionAddresses);
  await WhiteList_ERC20(erc20Addresses);
  console.log("Whitelist process completed!");
};

main().catch((err) => {
  console.error("Error in main:", err.message);
});
