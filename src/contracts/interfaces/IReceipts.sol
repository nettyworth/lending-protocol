// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ReceiptInterface {

    struct Receipt {
        address holder;
        uint256 receiptId;
    }

    // struct LenderReceipt {
    //     uint256 loanIndex;
    //     uint256 amount;
    //     uint256 timestamp;
    // }

    function open() external view returns (bool);

    function burnReceipt(uint256 tokenId) external;

    function ownerOf(uint256) external view returns (address);

    function tokenExist(uint256) external view returns (bool);

    function generateReceipt(
        address nftContractAddress,
        uint256[] calldata tokenIds,
        address holder
    ) external returns (uint256);

    // function generateBorrowerReceipt(address nftContractAddress, uint256 tokenId, address borrower) external returns (uint256);

    function getReceiptId(address nftContractAddress, uint256[] calldata tokenIds)external view returns(uint256 lenderReceiptId, address lenderAddress);

}
