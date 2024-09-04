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

    function generateLenderReceipt(address lender) external returns (uint256);

    function generateBorrowerReceipt(address borrower) external returns (uint256);

    function burnReceipt(uint256 tokenId) external;

    function tokenExist(uint256) external view returns (bool);

    function ownerOf(uint256) external view returns (address);

    function open() external view returns (bool);
}
