const { ethers } = require("ethers"); // Import the ethers library

const SECRET_SIGNER_PRIVATE_KEY =
  "45368821537686a5a8afeb4ee89b127af53cee27ce2850ca272764181f5b6b87"; // Ensure the private key is prefixed with '0x'

// const SECRET_SIGNER_PRIVATE_KEY =
//   "cad64b32ccae3f80a422387aa8e709c2fb321aa77738b9596f938ef9fac2a764";

// Initialize a provider using Infura's Sepolia testnet endpoint
const provider = new ethers.providers.JsonRpcProvider(
  "https://sepolia.infura.io/v3/3df44251533e4df3b1f0407d6ec4f34b"
);

// Create a signer instance from the private key
const signer = new ethers.Wallet(SECRET_SIGNER_PRIVATE_KEY, provider);

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
  interestRate,
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
      interestRate,
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
  interestRate,
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
      interestRate,
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
  interestRate,
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
      interestRate,
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
  interestRate,
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
      interestRate,
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

// nftContract: 0x358aa13c52544eccef6b0add0f801012adad5ee3;
// tokenId = 1;
// borrower = 0xab8483f64d9c6d1ecf9b849ae677dd3315835cb2;
// erc20 = 0xd8b934580fce35a11b58c6d73adee468a2833fa8;
// lender = 0x4b20993bc481177ec7e8f571cecae8a9e22c02db;
const main = async () => {
  //   const getsign = await signOffer(
  //     1,
  //     "0xe62b5Fa383dFfbD2e9ad429155612d7fAAEDBA04",
  //     "0x08f7Cde6109a74BA43Eaf316e5DaD5D27f63Ff7B",
  //     10000000000000000000n,
  //     20,
  //     1727936604,
  //     "0x2DC67345a60b5f2BA1d4f4bB661F6Ec31AF6B061",
  //     223898,
  //     "0xa611531661B5649688605a16ca7a245980F69A99"
  //   );

  //   console.log("Sign Offer signature", getsign);

  //   const getacceptLoanRequest = await acceptLoanRequest(
  //     2, // TokenId
  //     "0xe9318493c0fd30140afa8ecc47467b36da23855e", //nftContractAddress,
  //     "0x4E2b47AdCFcEB40c0bb1Dd283a7E539B26CFF8c4", //erc20TokenAddress,
  //     "0xa611531661B5649688605a16ca7a245980F69A99", //borrower,
  //     10000000000000000000n, //loanAmount,
  //     2000, //interestRate,
  //     1728482023, //loanDuration,
  //     54321 //nonce
  //   );

  //   console.log("getacceptLoanRequest", getacceptLoanRequest);

  const getacceptLoanCollectionOffer = await acceptLoanCollectionOffer(
    "0xe9318493c0fd30140afa8ecc47467b36da23855e", //     collectionAddress,
    "0x4E2b47AdCFcEB40c0bb1Dd283a7E539B26CFF8c4", //     erc20TokenAddress,
    "0x2DC67345a60b5f2BA1d4f4bB661F6Ec31AF6B061", //     lender,
    10000000000000000000n, //     loanAmount,
    2000, //     interestRate,
    1728482023, //     loanDuration,
    56789 //     nonce
  );

  console.log("getacceptLoanCollectionOffer", getacceptLoanCollectionOffer);

  //   const deposit = await signDeposit(
  //     "0x482CDDDff6adb44C0da472cfAA939fF615663025",
  //     1,
  //     "0x529Ece8c1995be3D4839912551565F1531037737"
  //   );

  //   console.log("Deposit Signature", deposit);

  //   const createloan = await signCreateLoan(
  //     1,
  //     "0x482CDDDff6adb44C0da472cfAA939fF615663025",
  //     "0x529Ece8c1995be3D4839912551565F1531037737",
  //     100,
  //     20,
  //     1725356782,
  //     "0xe393aeb31fe84c5b27d78ba3baa20ab3bf02d1c7",
  //     200202,
  //     "0x529ece8c1995be3d4839912551565f1531037737"
  //   );

  //   console.log("Create Loan Signature", createloan);
};

main();

// module.exports = {
//   signDeposit,
//   signOffer,
//   signCreateLoan,
// };
