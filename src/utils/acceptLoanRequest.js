const { ethers } = require("ethers");
require('dotenv').config()
const {BORROWER_PRIVATE_KEY, QUICKNODE_SEPOLIA_URL} = process.env;

const provider = new ethers.providers.JsonRpcProvider(QUICKNODE_SEPOLIA_URL);
const signer = new ethers.Wallet(BORROWER_PRIVATE_KEY, provider);

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

function sign(encoded) {
  const hash = ethers.utils.keccak256(encoded); // Create a keccak256 hash of the encoded data
  const signature = signer.signMessage(ethers.utils.arrayify(hash)); // Sign the hash using the signer's private key
  return signature;
}

const main = async () => {

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
};

main();

module.exports = {
  acceptLoanRequest
};
