// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ICryptoVault {
    function deposit(address, address, uint256) external;

    function withdraw(address, uint256, address) external;

    function isAssetStored(address, uint256) external view returns (bool);

    function attachReceiptToNFT(address, uint256, uint256) external;
    
    function unattachReceiptToNFT(address nftColletralAddress,uint256 tokenId,uint256 receiptId) external;
}
