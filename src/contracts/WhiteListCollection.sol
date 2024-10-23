// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

contract WhiteListCollection is Ownable{

    uint256 public totalWhitelistCollection;
    uint256 public totalWhitelistErc20Token;

    mapping(address => bool) private _whiteListCollection;
    mapping(address => bool) private _whiteListErc20Token;

    constructor() Ownable(msg.sender) {}

    function isWhiteListCollection(address _collectionAddress) public view returns(bool){
        return _whiteListCollection[_collectionAddress];
    }

    function isWhiteListErc20Token(address _Erc20Address) public view returns(bool){
        return _whiteListErc20Token[_Erc20Address];
    }

    function whiteListCollection(address[] memory _collectionAddresses) external onlyOwner {
        uint256 whitelistSize =  _collectionAddresses.length;
        totalWhitelistCollection += whitelistSize;
        require(whitelistSize != 0, "Not able to call this with empty CollectionAddresses");
        if(whitelistSize == 1){ 
            _whiteListCollection[_collectionAddresses[0]] = true;
        }
        else{
            for(uint256 index; index < whitelistSize; ){
            _whiteListCollection[_collectionAddresses[index]] = true;
            unchecked { index++; }
            }
        }
    }

    function blackListCollection(address[] memory _collectionAddresses) external onlyOwner {
        uint256 whitelistSize =  _collectionAddresses.length;
        totalWhitelistCollection -= whitelistSize;
        require(whitelistSize != 0, "Not able to call this with empty CollectionAddresses");

        if(whitelistSize == 1){
            _whiteListCollection[_collectionAddresses[0]] = false;
        }
        else{
            for(uint256 index; index < whitelistSize; ){
            _whiteListCollection[_collectionAddresses[index]] = false;
            unchecked { index++; }
            }
        }
    }

    function whiteListErc20Token(address[] memory _Erc20Addresses) external onlyOwner {
        uint256 whitelistSize =  _Erc20Addresses.length;
        totalWhitelistErc20Token += whitelistSize;

        require(whitelistSize != 0, "Not able to call this with empty CollectionAddresses");

        if(whitelistSize == 1){
            _whiteListErc20Token[_Erc20Addresses[0]] = true;
        }
        else{
            for(uint256 index; index < whitelistSize; ){
            _whiteListErc20Token[_Erc20Addresses[index]] = true;
            unchecked { index++; }
            }
        }
    }

    function blackListErc20Token(address[] memory _Erc20Addresses) external onlyOwner {
        uint256 whitelistSize =  _Erc20Addresses.length;
        totalWhitelistErc20Token -= whitelistSize;
        require(whitelistSize != 0, "Not able to call this with empty CollectionAddresses");

        if(whitelistSize == 1){
            _whiteListErc20Token[_Erc20Addresses[0]] = false;
        }
        else{
            for(uint256 index; index < whitelistSize; ){
            _whiteListErc20Token[_Erc20Addresses[index]] = false;
            unchecked { index++; }
            }
        }
    }
    
    function renounceOwnership() public view override onlyOwner {
    }

}