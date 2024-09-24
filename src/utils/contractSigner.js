const { ethers } = require("ethers");
require("dotenv").config();
const { BORROWER_PRIVATE_KEY, QUICKNODE_SEPOLIA_URL } = process.env;

// Initialize a provider using Infura's Sepolia testnet endpoint
const provider = new ethers.providers.JsonRpcProvider(QUICKNODE_SEPOLIA_URL);
// Create a signer instance from the private key
const signer = new ethers.Wallet(BORROWER_PRIVATE_KEY, provider);
// Function to sign a deposit operation
const signDeposit = function (contract, tokenId, walletAddress) {
  const encoded = ethers.utils.defaultAbiCoder.encode(
    ["address", "uint256", "address"],
    [contract, tokenId, walletAddress]
  );
  return sign(encoded);
};

// Function to sign an offer operation
const signOffer = async function (
  tokenId,
  contract,
  erc20TokenAddress,
  loanAmount,
  aprBasisPoints,
  loanDuration,
  lender,
  lenderNonce,
  borrower
) {
  const encoded = ethers.utils.defaultAbiCoder.encode(
    [
      "uint256",
      "address",
      "address",
      "uint256",
      "uint256",
      "uint256",
      "address",
      "uint256",
      "address",
    ],
    [
      tokenId,
      contract,
      erc20TokenAddress,
      loanAmount,
      aprBasisPoints,
      loanDuration,
      lender,
      lenderNonce,
      borrower,
    ]
  );
  return sign(encoded);
};

// Function to sign a loan creation operation
const signCreateLoan = function (
  tokenId,
  contract,
  erc20TokenAddress,
  loanAmount,
  aprBasisPoints,
  loanDuration,
  lender,
  nonce,
  borrower
) {
  const encoded = ethers.utils.defaultAbiCoder.encode(
    [
      "uint256",
      "address",
      "address",
      "uint256",
      "uint256",
      "uint256",
      "address",
      "uint256",
      "address",
    ],
    [
      tokenId,
      contract,
      erc20TokenAddress,
      loanAmount,
      aprBasisPoints,
      loanDuration,
      lender,
      nonce,
      borrower,
    ]
  );
  return sign(encoded);
};

const acceptLoanRequest = async function (
  tokenId,
  nftContractAddress,
  erc20TokenAddress,
  borrower,
  loanAmount,
  aprBasisPoints,
  loanDuration,
  nonce
) {
  const encoded = ethers.utils.defaultAbiCoder.encode(
    [
      "uint256",
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
      nftContractAddress,
      erc20TokenAddress,
      borrower,
      loanAmount,
      aprBasisPoints,
      loanDuration,
      nonce,
    ]
  );
  return sign(encoded);
};

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
  const getsign = await signOffer(
    1,
    "0xe62b5Fa383dFfbD2e9ad429155612d7fAAEDBA04",
    "0x08f7Cde6109a74BA43Eaf316e5DaD5D27f63Ff7B",
    10000000000000000000n,
    20,
    1727936604,
    "0x2DC67345a60b5f2BA1d4f4bB661F6Ec31AF6B061",
    223898,
    "0xa611531661B5649688605a16ca7a245980F69A99"
  );
  console.log("Sign Offer signature", getsign);
  const getacceptLoanRequest = await acceptLoanRequest(
    1, // TokenId
    "0x5fEa03d2718c4C42Ffbb051766a14C3b8aC1205e", //nftContractAddress,
    "0x10094F060Bae53A18723b941735c7dd28A844875", //erc20TokenAddress,
    "0xa611531661B5649688605a16ca7a245980F69A99", //borrower,
    10000000000000000000n, //loanAmount,
    500, // 5% aprBasisPoints,
    1729223075, //loanDuration,
    6734 //nonce
  );

  console.log("getacceptLoanRequest", getacceptLoanRequest);
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
  acceptLoanCollectionOffer,
  acceptLoanRequest,
  signCreateLoan,
};
