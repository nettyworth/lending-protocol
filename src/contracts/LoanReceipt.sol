// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./utils/ERC721A.sol";

contract LoanReceipt is ERC721A, Ownable {
    using Strings for uint256;
    bool public open;
    bool private _proposedState; 
    string public baseURI;
    mapping(uint256 => string) private _tokenURIs;
    mapping (uint256 => uint256 ) private _receipt;
    event ReceiptTransferred(address indexed currentBorrower, address newBorrower, uint256 receiptId);
    address public _proxy;
    address private _proposeproxy;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721A(_name, _symbol) Ownable(msg.sender) {}

    function _mintReceipt(address to) internal  {
        _safeMint(to, 1);
    }

    function transferReceipt(address currentHolder, address newHolder, uint256 receiptId) external onlyProxyManager {
        safeTransferFrom(currentHolder, newHolder, receiptId);
        emit ReceiptTransferred(currentHolder, newHolder, receiptId);
    }

    function generateReceipt(uint256 loanId, address holder) external onlyProxyManager returns (uint256){
        require(open, "Contract closed");
        _mintReceipt(holder);
        uint256 nftId = _nextTokenId() - 1;
         _receipt[loanId] =  nftId;
    return nftId;
    }

    function getReceiptId(uint256 loanId) external view returns(uint256 holderReceiptId, address holderAddress){
        holderReceiptId= _receipt[loanId];
        holderAddress =  ownerOf(holderReceiptId);
    return (holderReceiptId, holderAddress);
    }

    function burnReceipt(uint256 _tokenId) external onlyProxyManager {
        _burn(_tokenId);
    }

    function proposeSetState(bool newState) external onlyOwner {
        require(open != newState, "State already set to the desired value.");
        _proposedState = newState;
    }

    function applyProposedState() external onlyOwner {
        require(open != _proposedState, "Proposed state matches current state.");
        open = _proposedState;
        _proposedState = open;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI;

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyProxyManager() {
        require(
            _proxy == _msgSender(),
            "Ownable: caller is not the orchestrator"
        );
        _;
    }

    function proposeProxyManager(address newProxy) external onlyOwner {
        require(newProxy != address(0), "200:ZERO_ADDRESS");
        _proposeproxy = newProxy;
    }

    function setProxyManager() external onlyOwner {
        require(_proposeproxy != address(0), "200:ZERO_ADDRESS");
        _proxy = _proposeproxy;
        _proposeproxy = address(0);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenExist(uint256 id) external view returns (bool) {
        return _exists(id);
    }

    function renounceOwnership() public view override onlyOwner {
    }
}
