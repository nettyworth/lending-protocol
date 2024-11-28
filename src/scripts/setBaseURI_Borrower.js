const { ethers } = require("ethers");
require("dotenv").config();

const {
  ADMIN_PRIVATE_KEY,
  QUICKNODE_SEPOLIA_URL,
  LoanReceiptBorrower_Address,
} = process.env;

const {
  abi: LoanReceiptAbi,
} = require("../artifacts/src/contracts/LoanReceipt.sol/LoanReceipt.json");

const provider = new ethers.JsonRpcProvider(QUICKNODE_SEPOLIA_URL);
const admin = new ethers.Wallet(ADMIN_PRIVATE_KEY, provider);

const LoanReceiptBorrower = new ethers.Contract(
  LoanReceiptBorrower_Address,
  LoanReceiptAbi,
  admin
);

async function loanReceiptBorrower(baseURI) {
  if (typeof baseURI !== "string") {
    throw new Error("baseURI must be a string");
  }
  try {
    const tx = await LoanReceiptBorrower.setBaseURI(baseURI);
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
