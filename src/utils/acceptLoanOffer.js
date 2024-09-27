const { ethers } = require("ethers");
require("dotenv").config();
const { LENDER_PRIVATE_KEY, QUICKNODE_SEPOLIA_URL } = process.env;
console.log(
  "LENDER_PRIVATE_KEY, QUICKNODE_SEPOLIA_URL",
  LENDER_PRIVATE_KEY,
  QUICKNODE_SEPOLIA_URL
);

const provider = new ethers.providers.JsonRpcProvider(QUICKNODE_SEPOLIA_URL);
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
  const encoded = ethers.utils.defaultAbiCoder.encode(
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
  return sign(encoded);
};

// Function to sign encoded data
function sign(encoded) {
  const hash = ethers.utils.keccak256(encoded); // Create a keccak256 hash of the encoded data
  const signature = signer.signMessage(ethers.utils.arrayify(hash)); // Sign the hash using the signer's private key
  return signature;
}

const main = async () => {
  const getsign = await signOffer(
    2,
    "0x5fEa03d2718c4C42Ffbb051766a14C3b8aC1205e",
    "0x10094F060Bae53A18723b941735c7dd28A844875",
    "0x2DC67345a60b5f2BA1d4f4bB661F6Ec31AF6B061",
    "0xa611531661B5649688605a16ca7a245980F69A99",
    10000000000000000000n,
    500,
    1729223075,
    223898
  );
  console.log("Sign Offer signature", getsign);
};

main();

module.exports = {
  signOffer,
};
