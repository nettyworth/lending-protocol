// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ReceiptInterface {
    function open() external view returns (bool);

    function burnReceipt(uint256 tokenId) external;

    function ownerOf(uint256) external view returns (address);

    function tokenExist(uint256) external view returns (bool);

    function generateReceipt(uint256 loanId, address holder) external returns (uint256);

    function transferReceipt(address currentHolder, address newHolder, uint256 receiptId) external;

    function getReceiptId(uint256 loanId) external view returns(uint256 holderReceiptId, address holderAddress);
}
