const { ethers } = require('hardhat');
require('dotenv').config();
const {
  ERC20_ADDRESS,
  NFT_ADDRESS,
  LENDER_PRIVATE_KEY,
  BORROWER_PRIVATE_KEY,
  QUICKNODE_SEPOLIA_URL,
  Vault_ADDRESS,
} = process.env;

const provider = new ethers.JsonRpcProvider(QUICKNODE_SEPOLIA_URL);
const lender = new ethers.Wallet(LENDER_PRIVATE_KEY, provider);
const borrower = new ethers.Wallet(BORROWER_PRIVATE_KEY, provider);

const {
  abi: nftAbi,
} = require('../contracts/examples/artifacts/NFTExample.json');
const nftContract = new ethers.Contract(NFT_ADDRESS, nftAbi, provider);

const {
  abi: erc0Abi,
} = require('../contracts/examples/artifacts/ERC20Example.json');
const erc20Contract = new ethers.Contract(ERC20_ADDRESS, erc0Abi, provider);

async function approveTokens() {
  try {
    console.log('Approving erc20 to vault with the account:', lender.address);
    const tx = await erc20Contract
      .connect(lender)
      .approve(Vault_ADDRESS, ethers.MaxUint256);

    const receipt = await tx.wait();
    console.log(
      'Lender approved max-erc20 to vault, Transaction successful with hash:',
      receipt.hash
    );

    console.log('Approving erc20 to vault with the account:', borrower.address);
    const tx2 = await erc20Contract
      .connect(borrower)
      .approve(Vault_ADDRESS, ethers.MaxUint256);

    const receipt2 = await tx2.wait();
    console.log(
      'Borrower approved max-erc20 to vault, Transaction successful with hash:',
      receipt2.hash
    );

    console.log('Approving NFT to vault with the account:', borrower.address);
    const tx3 = await nftContract
      .connect(borrower)
      .setApprovalForAll(Vault_ADDRESS, true);

    const receipt3 = await tx3.wait();
    console.log(
      'Borrowe approved NFT to vault, Transaction successful with hash:',
      receipt3.hash
    );
  } catch (error) {
    console.error('Error during transaction:', error);
  }
}

approveTokens()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
