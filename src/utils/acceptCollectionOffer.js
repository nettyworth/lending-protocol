const ethers = require("ethers");
require("dotenv").config();
const { LENDER_PRIVATE_KEY, QUICKNODE_SEPOLIA_URL } = process.env;
// console.log(
//   "LENDER_PRIVATE_KEY,QUICKNODE_SEPOLIA_URL",
//   LENDER_PRIVATE_KEY,
//   QUICKNODE_SEPOLIA_URL
// );

const abiCoder = new ethers.AbiCoder();
const provider = new ethers.JsonRpcProvider(QUICKNODE_SEPOLIA_URL);
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
  const encoded = abiCoder.encode(
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
  return await sign(encoded);
};

// Function to sign encoded data
async function sign(encoded) {
  const hash = ethers.keccak256(encoded); // Create a keccak256 hash of the encoded data
  const signature = await signer.signMessage(ethers.getBytes(hash)); // Sign the hash using the signer's private key
  return signature;
}

const main = async () => {
  const getacceptLoanCollectionOffer = await acceptLoanCollectionOffer(
    "0x5fEa03d2718c4C42Ffbb051766a14C3b8aC1205e", //     collectionAddress,
    "0x10094F060Bae53A18723b941735c7dd28A844875", //     erc20TokenAddress,
    "0x2DC67345a60b5f2BA1d4f4bB661F6Ec31AF6B061", //     lender,
    10000000000000000000n, //     loanAmount,
    500, //  5% aprBasisPoints,
    1727907073, //     loanDuration,
    13211 //     nonce
  );
  console.log("getacceptLoanCollectionOffer", getacceptLoanCollectionOffer);
};

main();

module.exports = {
  acceptLoanCollectionOffer,
};

//tuple pass in the function
[
  "0xddaAd340b0f1Ef65169Ae5E41A8b10776a75482d",
  "0x0fC5025C764cE34df352757e82f7B5c4Df39A836",
  "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",
  10000000000000000000,
  500,
  1729251102,
  1
]
