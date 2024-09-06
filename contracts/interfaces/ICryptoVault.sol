// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ICryptoVault {
    function depositNftToEscrowAndERC20ToBorrower(
        address nftContract,
        uint256 tokenId,
        address currencyERC20,
        address lender,
        address borrower,
        uint256 loanAmount
        ) external;

    function withdrawNftFromEscrowAndERC20ToLender(
        address nftContract,
        uint256 tokenId,
        address borrower,
        address lender,
        uint256 remainingAmount,
        address currencyERC20
        ) external;
    
    function withdrawNftFromEscrow(
        address nftContract,
        uint256 tokenId,
        address borrower
        ) external;
    
    function withdrawNftFromEscrow(
      address nftContract,
        uint256 tokenId,
        address borrower,
        address lender
    ) external;

    function AssetStoredOwner( 
        address tokenAddress, 
        uint256 tokenId
    ) external view returns (address);

}
