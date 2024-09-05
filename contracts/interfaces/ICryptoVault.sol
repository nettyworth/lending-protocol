// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ICryptoVault {
    function deposit(address, address, uint256) external;

    function depositNftToEscrowAndERC20ToBorrower(
        address nftContract,
        uint256 tokenId,
        address currencyERC20,
        address lender,
        address borrower,
        uint256 loanAmount
        ) external returns(uint256 receiptIdBorrower, uint256 receiptIdLender);

    function withdraw(address, uint256, address) external;

    function AssetStoredOwner( address tokenAddress, uint256 tokenId) external view returns (address);

    // function attachReceiptToNFT(address, uint256, uint256) external;
    
    // function unattachReceiptToNFT(address nftColletralAddress,uint256 tokenId,uint256 receiptId) external;
}
