const ethers = require("ethers");
require("dotenv").config();
const { BORROWER_PRIVATE_KEY, QUICKNODE_SEPOLIA_URL } = process.env;
console.log(BORROWER_PRIVATE_KEY);

const provider = new ethers.JsonRpcProvider(QUICKNODE_SEPOLIA_URL);
const signer = new ethers.Wallet(BORROWER_PRIVATE_KEY, provider);

const abiCoder = new ethers.AbiCoder();

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
  const encoded = abiCoder.encode(
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
  return await sign(encoded);
};

async function sign(encoded) {
  const hash = ethers.keccak256(encoded); // Create a keccak256 hash of the encoded data
  const signature = await signer.signMessage(ethers.getBytes(hash)); // Sign the hash using the signer's private key
  return signature;
}

const main = async () => {
  const getacceptLoanRequest = await acceptLoanRequest(
    8, // TokenId
    "0x5fEa03d2718c4C42Ffbb051766a14C3b8aC1205e", //nftContractAddress,
    "0x10094F060Bae53A18723b941735c7dd28A844875", //erc20TokenAddress,
    "0xa611531661B5649688605a16ca7a245980F69A99", //borrower,
    10000000000000000000n, //loanAmount,
    500, // 5% aprBasisPoints,
    1727907073, //loanDuration,
    22222 //nonce
  );

  console.log("getacceptLoanRequest", getacceptLoanRequest);
};

main();

module.exports = {
  acceptLoanRequest,
};
// command
// node src/utils/acceptLoanOffer.js

// tuple  pass in request loan offer
[
  3,
  "0xddaAd340b0f1Ef65169Ae5E41A8b10776a75482d",
  "0x0fC5025C764cE34df352757e82f7B5c4Df39A836",
  "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
  10000000000000000000,
  500,
  1729253900,
  3
][
  (3,
  "0xddaAd340b0f1Ef65169Ae5E41A8b10776a75482d",
  "0x0fC5025C764cE34df352757e82f7B5c4Df39A836",
  "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",
  "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
  10000000000000000000,
  500,
  1729253200,
  3)
];