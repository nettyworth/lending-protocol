// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

contract WhiteListCollection is Ownable{

    mapping(address => bool) private _whiteListCollection;


    constructor() Ownable(msg.sender) {}

    function isWhiteList(address _collectionAddress) public view returns(bool){

        return _whiteListCollection[_collectionAddress];
    }
// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db","0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"]

    function whiteListCollection(address[] memory _collectionAddresses) external onlyOwner {

        uint256 whitelistSize =  _collectionAddresses.length;
        require(whitelistSize != 0, "Not able to call this with empty CollectionAddresses");

        if(whitelistSize <= 1){
            _whiteListCollection[_collectionAddresses[0]] = true;
        }
        else{
            for(uint256 index; index < whitelistSize; index ++ ){
            _whiteListCollection[_collectionAddresses[index]] = true;
            }
        }
    }

    function blackListCollection(address[] memory _collectionAddresses) external onlyOwner {

        uint256 whitelistSize =  _collectionAddresses.length;
        require(whitelistSize != 0, "Not able to call this with empty CollectionAddresses");

        if(whitelistSize <= 1){
            _whiteListCollection[_collectionAddresses[0]] = false;
        }
        else{
            for(uint256 index; index < whitelistSize; index ++ ){
            _whiteListCollection[_collectionAddresses[index]] = false;
            }
        }
    }

}