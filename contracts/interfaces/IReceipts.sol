// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ReceiptInterface {

    struct BorrowerReceipt {
        uint256 loanIndex;
        uint256 amount;
        uint256 timestamp;
    }

    struct LenderReceipt {
        uint256 loanIndex;
        uint256 amount;
        uint256 timestamp;
    }

    function generateLenderReceipt(address nftContractAddress, uint256 tokenId,address lender) external returns (uint256);

    function generateBorrowerReceipt(address nftContractAddress, uint256 tokenId, address borrower) external returns (uint256);

    function burnReceipt(uint256 tokenId) external;

    function getBorrowerReceiptId(address nftContractAddress, uint256 tokenId)external view returns(uint256 borrowerReceiptId, address borrowerAddress);

    function getLenderReceiptId(address nftContractAddress, uint256 tokenId)external view returns(uint256 lenderReceiptId, address lenderAddress);

    function tokenExist(uint256) external view returns (bool);

    function ownerOf(uint256) external view returns (address);

    function open() external view returns (bool);
}
