const ethers = require("ethers");
require("dotenv").config();
const { LENDER_PRIVATE_KEY, QUICKNODE_SEPOLIA_URL } = process.env;
// console.log(
//   "LENDER_PRIVATE_KEY, QUICKNODE_SEPOLIA_URL",
//   LENDER_PRIVATE_KEY,
//   QUICKNODE_SEPOLIA_URL
// );

const abiCoder = new ethers.AbiCoder();
const provider = new ethers.JsonRpcProvider(QUICKNODE_SEPOLIA_URL);
const signer = new ethers.Wallet(LENDER_PRIVATE_KEY, provider);

// Function to sign an offer operation
const signOffer = async function (
  tokenId,
  contract,
  erc20TokenAddress,
  lender,
  borrower,
  loanAmount,
  aprBasisPoints,
  loanDuration,
  lenderNonce
) {
  const encoded = abiCoder.encode(
    [
      "uint256",
      "address",
      "address",
      "address",
      "address",
      "uint256",
      "uint256",
      "uint256",
      "uint256",
    ],
    [
      tokenId,
      contract,
      erc20TokenAddress,
      lender,
      borrower,
      loanAmount,
      aprBasisPoints,
      loanDuration,
      lenderNonce,
    ]
  );
  return await sign(encoded);
};

// Function to sign encoded data
async function sign(encoded) {
  const hash = ethers.keccak256(encoded); // Create a keccak256 hash of the encoded data
  const signature = await signer.signMessage(ethers.getBytes(hash)); // Sign the hash using the signer's private key
  return signature;
}

const main = async () => {
  const getsign = await signOffer(
    6,
    "0x5fEa03d2718c4C42Ffbb051766a14C3b8aC1205e",
    "0x10094F060Bae53A18723b941735c7dd28A844875",
    "0x2DC67345a60b5f2BA1d4f4bB661F6Ec31AF6B061",
    "0xa611531661B5649688605a16ca7a245980F69A99",
    10000000000000000000n,
    500,
    1729223075,
    1111
  );
  console.log("Sign Offer signature", getsign);
};

main();

module.exports = {
  signOffer,
};

// tuple  pass in Accept loan offer
// [
//   6,
//   "0x5fEa03d2718c4C42Ffbb051766a14C3b8aC1205e",
//   "0x10094F060Bae53A18723b941735c7dd28A844875",
//   "0x2DC67345a60b5f2BA1d4f4bB661F6Ec31AF6B061",
//   "0xa611531661B5649688605a16ca7a245980F69A99",
//   10000000000000000000,
//   500,
//   1729223075,
//   1111
// ]
