// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IwhiteListCollection {
    function blackListErc20Token(address[] memory _Erc20Addresses) external;
    
    function whiteListErc20Token(address[] memory _Erc20Addresses) external;
    
    function whiteListCollection(address[] memory _collectionAddresses) external;

    function blackListCollection(address[] memory _collectionAddresses) external;

    function isWhiteListErc20Token(address _Erc20Address) external view returns(bool);
 
    function isWhiteListCollection(address _collectionAddress) external view returns(bool);
}
