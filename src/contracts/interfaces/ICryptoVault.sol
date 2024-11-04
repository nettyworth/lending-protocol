// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ICryptoVault {
    function depositNftToEscrowAndERC20ToBorrower(
        address nftContract,
        uint256 loanId,
        uint256[] calldata tokenIds,
        address currencyERC20,
        address lender,
        address borrower,
        uint256 loanAmount
        ) external;

    function withdrawNftFromEscrowAndERC20ToLender(
        address nftContract,
        uint256 loanId,
        uint256[] calldata tokenIds,
        address borrower,
        address lender,
        uint256 rePaymentAmount,
        uint256 computeAdminFee,
        address currencyERC20,
        address adminWallet
        ) external;
    
    function withdrawNftFromEscrow(
        address nftContract,
        uint256 loanId,
        uint256[] calldata tokenIds,
        address borrower,
        address lender
    ) external;

    function AssetStoredOwner( 
        address tokenAddress, 
        uint256 tokenId
    ) external view returns (address);

}
