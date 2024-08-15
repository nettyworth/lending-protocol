// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface CryptoVaultInterface {
    function deposit(address, uint256) external;

    function withdraw(address, uint256, address) external;

    function isAssetStored(address, uint256) external view returns (bool);

    function attachReceiptToNFT(address, uint256, uint256) external;
}
