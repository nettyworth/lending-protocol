// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ReceiptInterface {

    // struct Receipt {
    //     address holder;
    //     uint256 receiptId;
    // }

    function open() external view returns (bool);

    function burnReceipt(uint256 tokenId) external;

    function ownerOf(uint256) external view returns (address);

    function tokenExist(uint256) external view returns (bool);

    function generateReceipt(
        // address nftContractAddress,
        // uint256[] calldata tokenIds,
        uint256 loanId,
        address holder
    ) external returns (uint256);

     function transferReceipt(address currentHolder, address newHolder, uint256 receiptId) external;

    // function getReceiptId(address nftContractAddress, uint256[] calldata tokenIds)external view returns(uint256 lenderReceiptId, address lenderAddress);

    function getReceiptId(uint256 loanId) external view returns(uint256 holderReceiptId, address holderAddress);
}
