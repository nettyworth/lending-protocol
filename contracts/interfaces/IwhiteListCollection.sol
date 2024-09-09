// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IwhiteListCollection {
 
    function isWhiteList(address _collectionAddress) external view returns(bool);

    function whiteListCollection(address[] memory _collectionAddresses) external;

    function blackListCollection(address[] memory _collectionAddresses) external;
}
