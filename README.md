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

NettyWorth lending protocol is a decentralized finance (DeFi) project that allows users to use their NFTs as collateral for loans. The system consists of several smart contracts that work together to facilitate NFT-backed loans.

## Prerequisites

- Node.js (v14.0.0 or later)
- npm (v6.0.0 or later)
- Git
- Metamask or another Ethereum wallet
- QuickNode account for blockchain access
- Etherscan API key (for contract verification)

## Project Setup

1. Clone the repository:

   ```
   git clone https://github.com/your-username/nettyworth-project.git
   cd nettyworth-project
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
3. **LoanReceipt**: An ERC721 token representing loan receipts.
4. **NettyWorthProxy**: The main contract that orchestrates interactions between other contracts.
5. **TestToken**: An ERC721 token for testing purposes.
6. **MyToken**: An ERC20 token for testing purposes.

### High-Level Function Overview

#### CryptoVault

- `deposit`: Allows users to deposit NFTs as collateral.
- `withdraw`: Allows users to withdraw their NFTs after loan repayment.
- `isAssetStored`: Checks if an NFT is stored in the vault.

#### LoanManager

- `createLoan`: Creates a new loan.
- `makePayment`: Processes loan payments.
- `getLoan`: Retrieves loan information.

#### LoanReceipt

- `generateReceipts`: Mints receipt tokens for lenders.
- `generateBorrowerReceipt`: Mints receipt tokens for borrowers.
- `burnReceipt`: Burns a receipt token.

#### NettyWorthProxy

- `depositToEscrow`: Deposits an NFT into the vault.
- `claimFromEscrow`: Withdraws an NFT from the vault.
- `makeOffer`: Makes a loan offer.
- `approveLoan`: Approves a loan offer.
- `payLoan`: Processes a loan payment.
- `claimToken`: Claims an NFT after loan repayment.
- `claimERC20`: Claims ERC20 tokens after loan default.

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

  // Example: Make a loan offer
  const tx = await proxy.makeOffer(/* parameters */);
  await tx.wait();
  console.log("Offer made successfully");
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

For more help, please open an issue in the GitHub repository.
