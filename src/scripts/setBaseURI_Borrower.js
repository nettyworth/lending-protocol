const { ethers } = require("ethers");
import { fetchGasFees } from "./gasFees.js";
require("dotenv").config();

const {
  ADMIN_PRIVATE_KEY,
  QUICKNODE_SEPOLIA_URL,
  LOAN_RECEIPT_BORROWER_CONTRACT_ADDRESS,
} = process.env;

const {
  abi: LoanReceiptAbi,
} = require("../artifacts/src/contracts/LoanReceipt.sol/LoanReceipt.json");

const provider = new ethers.JsonRpcProvider(QUICKNODE_SEPOLIA_URL);
const admin = new ethers.Wallet(ADMIN_PRIVATE_KEY, provider);

const LoanReceiptBorrower = new ethers.Contract(
  LOAN_RECEIPT_BORROWER_CONTRACT_ADDRESS,
  LoanReceiptAbi,
  admin,
);

async function loanReceiptBorrower(baseURI) {
  if (typeof baseURI !== "string") {
    throw new Error("baseURI must be a string");
  }
  try {
    const { maxFeePerGasInGwei, maxPriorityFeePerGasInGwei } =
      await fetchGasFees();
    console.log("Max Fee Per Gas:", maxFeePerGasInGwei);
    console.log("Max Priority Fee Per Gas:", maxPriorityFeePerGasInGwei);
    const gasEstimate = await LoanReceiptBorrower.setBaseURI.estimateGas(
      baseURI,
      {
        maxFeePerGas: maxFeePerGasInGwei,
        maxPriorityFeePerGas: maxPriorityFeePerGasInGwei,
      },
    );
    const tx = await LoanReceiptBorrower.setBaseURI(baseURI, {
      gasLimit: gasEstimate.toString(),
      maxFeePerGas: maxFeePerGasInGwei,
      maxPriorityFeePerGas: maxPriorityFeePerGasInGwei,
    });
    console.log("Transaction submitted:", tx.hash);
    const receipt = await tx.wait();

    if (receipt.status === 1) {
      console.log("Transaction successfully mined!");
      const URI = await LoanReceiptBorrower.baseURI();
      console.log(URI);
      return receipt;
    } else {
      throw new Error("Transaction failed");
    }
  } catch (error) {
    console.error("setBaseURI Error:", error.message);
  }
}

const main = async () => {
  const baseURI = "https://www.myserver.com/metadata/";

  console.log("Start setting base URI process...");
  await loanReceiptBorrower(baseURI);
  console.log("Set BaseURI process completed!");
};

main().catch((err) => {
  console.error("Error in main:", err.message);
});
