const { ethers } = require("ethers");
const fs = require("fs");
const csv = require("csv-parse/sync");
import { fetchGasFees } from "./gasFees.js";
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

function readAddressesFromCSV(filePath) {
  try {
    const fileContent = fs.readFileSync(filePath, "utf-8");

    const addresses = fileContent
      .split("\n")
      .map((line) => line.trim())
      .filter((line) => line.length > 0);

    console.log(`Read ${addresses.length} addresses from ${filePath}`);
    return addresses;
  } catch (error) {
    console.error(`Error reading CSV file ${filePath}:`, error.message);
    return [];
  }
}

async function WhiteList_ERC20(whiteListERC20Addresses) {
  try {
    const { maxFeePerGasInGwei, maxPriorityFeePerGasInGwei } =
      await fetchGasFees();
    console.log("Max Fee Per Gas:", maxFeePerGasInGwei);
    console.log("Max Priority Fee Per Gas:", maxPriorityFeePerGasInGwei);
    const gasEstimate =
      await whiteListCollection.whiteListErc20Token.estimateGas(
        whiteListERC20Addresses,
        {
          maxFeePerGas: maxFeePerGasInGwei,
          maxPriorityFeePerGas: maxPriorityFeePerGasInGwei,
        },
      );
    const tx = await whiteListCollection.whiteListErc20Token(
      whiteListERC20Addresses,
      {
        gasLimit: gasEstimate.toString(),
        maxFeePerGas: maxFeePerGasInGwei,
        maxPriorityFeePerGas: maxPriorityFeePerGasInGwei,
      },
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
    const { maxFeePerGasInGwei, maxPriorityFeePerGasInGwei } =
      await fetchGasFees();
    console.log("Max Fee Per Gas:", maxFeePerGasInGwei);
    console.log("Max Priority Fee Per Gas:", maxPriorityFeePerGasInGwei);
    const gasEstimate =
      await whiteListCollection.whiteListCollection.estimateGas(
        whiteListCollectionAddresses,
        {
          maxFeePerGas: maxFeePerGasInGwei,
          maxPriorityFeePerGas: maxPriorityFeePerGasInGwei,
        },
      );
    const tx = await whiteListCollection.whiteListCollection(
      whiteListCollectionAddresses,
      {
        gasLimit: gasEstimate.toString(),
        maxFeePerGas: maxFeePerGasInGwei,
        maxPriorityFeePerGas: maxPriorityFeePerGasInGwei,
      },
    );
    console.log("Transaction submitted ::", tx.hash);
    const receipt = await tx.wait();
    console.log("Transaction mined if status is '1':", receipt.status);
  } catch (error) {
    console.error("whitelistCollection Error:", error.message);
  }
}

const main = async () => {
  // Read addresses from CSV files
  const erc20Addresses = readAddressesFromCSV(
    "./src/scripts/erc20Addresses.csv",
  );
  const collectionAddresses = readAddressesFromCSV(
    "./src/scripts/collectionAddresses.csv",
  );

  console.log("Starting whitelist process...");
  console.log("Collection addresses:", collectionAddresses);
  console.log("ERC20 addresses:", erc20Addresses);

  if (collectionAddresses.length > 0) {
    await WhiteList_Collection(collectionAddresses);
  } else {
    console.log("No collection addresses found in CSV");
  }

  if (erc20Addresses.length > 0) {
    await WhiteList_ERC20(erc20Addresses);
  } else {
    console.log("No ERC20 addresses found in CSV");
  }

  console.log("Whitelist process completed!");
};

main().catch((err) => {
  console.error("Error in main:", err.message);
});
