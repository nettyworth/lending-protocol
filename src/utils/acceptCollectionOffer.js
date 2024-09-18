const { ethers } = require("ethers");
require('dotenv').config()
const {BORROWER_PRIVATE_KEY,QUICKNODE_SEPOLIA_URL} = process.env;
console.log("BORROWER_PRIVATE_KEY,QUICKNODE_SEPOLIA_URL",BORROWER_PRIVATE_KEY,QUICKNODE_SEPOLIA_URL);
const provider = new ethers.providers.JsonRpcProvider(QUICKNODE_SEPOLIA_URL);
const signer = new ethers.Wallet(BORROWER_PRIVATE_KEY, provider);

const acceptLoanCollectionOffer = async function (
  collectionAddress,
  erc20TokenAddress,
  lender,
  loanAmount,
  aprBasisPoints,
  loanDuration,
  nonce
) {
  const encoded = ethers.utils.defaultAbiCoder.encode(
    [
      "address",
      "address",
      "address",
      "uint256",
      "uint256",
      "uint256",
      "uint256",
    ],
    [
      collectionAddress,
      erc20TokenAddress,
      lender,
      loanAmount,
      aprBasisPoints,
      loanDuration,
      nonce,
    ]
  );
  return sign(encoded);
};

// Function to sign encoded data
function sign(encoded) {
  const hash = ethers.utils.keccak256(encoded); // Create a keccak256 hash of the encoded data
  const signature = signer.signMessage(ethers.utils.arrayify(hash)); // Sign the hash using the signer's private key
  return signature;
}

const main = async () => {
  const getacceptLoanCollectionOffer = await acceptLoanCollectionOffer(
    "0xe9318493c0fd30140afa8ecc47467b36da23855e", //     collectionAddress,
    "0x4E2b47AdCFcEB40c0bb1Dd283a7E539B26CFF8c4", //     erc20TokenAddress,
    "0x2DC67345a60b5f2BA1d4f4bB661F6Ec31AF6B061", //     lender,
    10000000000000000000n, //     loanAmount,
    500, //  5% aprBasisPoints,
    1728482023, //     loanDuration,
    56789 //     nonce
  );
  console.log("getacceptLoanCollectionOffer", getacceptLoanCollectionOffer);
};

main();

module.exports = {
  acceptLoanCollectionOffer
};
