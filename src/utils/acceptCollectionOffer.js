const { ethers } = require("ethers");
require("dotenv").config();
const { LENDER_PRIVATE_KEY, QUICKNODE_SEPOLIA_URL } = process.env;
// console.log(
//   "LENDER_PRIVATE_KEY,QUICKNODE_SEPOLIA_URL",
//   LENDER_PRIVATE_KEY,
//   QUICKNODE_SEPOLIA_URL
// );
const provider = new ethers.providers.JsonRpcProvider(QUICKNODE_SEPOLIA_URL);
const signer = new ethers.Wallet(LENDER_PRIVATE_KEY, provider);

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
    "0x5fEa03d2718c4C42Ffbb051766a14C3b8aC1205e", //     collectionAddress,
    "0x10094F060Bae53A18723b941735c7dd28A844875", //     erc20TokenAddress,
    "0x2DC67345a60b5f2BA1d4f4bB661F6Ec31AF6B061", //     lender,
    10000000000000000000n, //     loanAmount,
    500, //  5% aprBasisPoints,
    1730028043, //     loanDuration,
    1321 //     nonce
  );
  console.log("getacceptLoanCollectionOffer", getacceptLoanCollectionOffer);
};

main();

module.exports = {
  acceptLoanCollectionOffer,
};

//tuple pass in the function
// [
//   "0x5fEa03d2718c4C42Ffbb051766a14C3b8aC1205e",
//   "0x10094F060Bae53A18723b941735c7dd28A844875",
//   "0x2DC67345a60b5f2BA1d4f4bB661F6Ec31AF6B061",
//   10000000000000000000,
//   500,
//   1730028043,
//   1321
// ]
