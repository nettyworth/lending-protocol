# NettyWorth Lending Protocol

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Project Setup](#project-setup)
4. [Smart Contracts](#smart-contracts)
5. [Local Development](#local-development)
6. [Testing](#testing)
7. [Deployment](#deployment)
8. [Contract Interaction](#contract-interaction)
9. [Troubleshooting](#troubleshooting)

## Overview

NettyWorth Lending Protocol is a decentralized finance (DeFi) project that enables users to use their NFTs as collateral for loans. The system comprises several smart contracts working together to facilitate NFT-backed loans, providing a seamless experience for borrowers and lenders.

## Prerequisites

- Node.js (v22.8.0 or later)
- npm (v10.8.2 or later)
- Git
- Metamask or another Ethereum wallet
- QuickNode account for blockchain access
- Etherscan API key (for contract verification)

## Project Setup

1. Clone the repository:

   Using HTTPS:

   ```
   git clone https://github.com/nettyworth/lending-protocol.git
   cd lending-protocol
   ```

   Using SSH:

   ```
   git clone git@github.com:nettyworth/lending-protocol.git
   cd lending-protocol
   ```

2. Install dependencies:

   ```
   npm install
   ```

3. Create a `.env` file in the project root and add the following:

   ```
   PRIVATE_KEY=your_private_key
   QUICKNODE_SEPOLIA_URL=your_quicknode_sepolia_endpoint
   QUICKNODE_HOLESKY_URL=your_quicknode_holesky_endpoint
   QUICKNODE_MAINNET_URL=your_quicknode_mainnet_endpoint
   ETHERSCAN_API_KEY=your_etherscan_api_key
   ```

   Replace the placeholder values with your actual credentials.

## Smart Contracts

The project consists of the following main contracts:

1. **CryptoVault**: Manages the storage of NFTs used as collateral.
2. **LoanManager**: Handles loan creation, payments, and loan state.
3. **LoanReceipt**: An ERC721A token representing loan receipts.
4. **NettyWorthProxy**: The main contract that orchestrates interactions between other contracts.
5. **WhiteListCollection**: Manages whitelisting of NFT collections and ERC20 tokens.

### Key Functions Overview

#### CryptoVault

- `depositNftToEscrowAndERC20ToBorrower`: Deposits an NFT into the vault and transfers ERC20 tokens to the borrower.
- `withdrawNftFromEscrowAndERC20ToLender`: Withdraws an NFT from the vault and transfers ERC20 tokens to the lender.
- `withdrawNftFromEscrow`: Withdraws an NFT from the vault.
- `AssetStoredOwner`: Checks if an NFT is stored in the vault and returns the owner.

#### LoanManager

- `createLoan`: Creates a new loan.
- `updateLoan`: Updates an existing loan.
- `getLoan`: Retrieves loan information.
- `getPayoffAmount`: Calculates the payoff amount for a loan.

#### LoanReceipt

- `generateLenderReceipt`: Mints receipt tokens for lenders.
- `generateBorrowerReceipt`: Mints receipt tokens for borrowers.
- `burnReceipt`: Burns a receipt token.

#### NettyWorthProxy

- `acceptLoanRequest`: Accepts a loan request from a borrower.
- `acceptLoanOffer`: Accepts a loan offer from a lender.
- `acceptLoanCollectionOffer`: Accepts a loan offer for a specific NFT collection.
- `payBackLoan`: Processes a loan repayment.
- `forCloseLoan`: Forecloses a loan after default.

#### WhiteListCollection

- `whiteListCollection`: Adds NFT collections to the whitelist.
- `blackListCollection`: Removes NFT collections from the whitelist.
- `whiteListErc20Token`: Adds ERC20 tokens to the whitelist.
- `blackListErc20Token`: Removes ERC20 tokens from the whitelist.

## Local Development

1. Start a local Hardhat node:

   ```
   npx hardhat node
   ```

2. In a new terminal, deploy contracts to the local network:
   ```
   npx hardhat run scripts/deploy.js --network localhost
   ```

## Testing

1. Run the test suite:

   ```
   npx hardhat test
   ```

2. For coverage report:
   ```
   npx hardhat coverage
   ```

## Deployment

### Testnet (Sepolia)

1. Ensure your `.env` file is set up with the correct QuickNode Sepolia URL and your private key.

2. Deploy to Sepolia:
   ```
   npx hardhat run scripts/deploy.js --network sepolia
   ```

### Mainnet

1. Ensure your `.env` file is set up with the correct QuickNode Mainnet URL and your private key.

2. Deploy to Mainnet:
   ```
   npx hardhat run scripts/deploy.js --network mainnet
   ```

**Note**: Always thoroughly test on testnets before deploying to mainnet. Consider a professional audit before mainnet deployment.

## Contract Interaction

After deployment, you can interact with the contracts using Hardhat tasks or by writing scripts. Here's an example of how to interact with the NettyWorthProxy contract:

```javascript
const { ethers } = require("hardhat");

async function main() {
  const NettyWorthProxy = await ethers.getContractFactory("NettyWorthProxy");
  const proxy = await NettyWorthProxy.attach("DEPLOYED_PROXY_ADDRESS");

  // Example: Accept a loan request
  const loanRequest = {
    nftContractAddress: "0x...",
    tokenId: 1,
    borrower: "0x...",
    loanAmount: ethers.utils.parseEther("1"),
    aprBasisPoints: 1000, // 10% APR
    loanDuration: Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60, // 30 days from now
    erc20TokenAddress: "0x...",
    nonce: 1,
  };

  const signature = "0x..."; // Borrower's signature

  const tx = await proxy.acceptLoanRequest(signature, loanRequest);
  await tx.wait();
  console.log("Loan request accepted successfully");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

## Troubleshooting

1. **Transaction Underpriced**: Increase the gas price in your Hardhat config or transaction parameters.

2. **Nonce too low**: Reset your account's nonce in Metamask or use the `--reset` flag with Hardhat.

3. **Contract verification fails**: Ensure you're using the correct Etherscan API key and that the contract code hasn't changed since deployment.

4. **Whitelist issues**: Make sure the NFT collection and ERC20 token are whitelisted using the WhiteListCollection contract before attempting to create or accept loans.

5. **Signature validation fails**: Ensure that the signature is correctly generated and matches the loan request or offer parameters.

6. **Insufficient allowance**: When accepting loan offers or repaying loans, make sure the required ERC20 tokens have been approved for the NettyWorthProxy contract.

For more help or to report issues, please open an issue in the GitHub repository: https://github.com/nettyworth/lending-protocol/issues
