// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LoanReceipt is ERC721A, ReentrancyGuard, Ownable {
    struct BorrowerReceipt {
        address borrower;
        uint256 receiptId;
    }

    struct LenderReceipt {
        address lender;
        uint256 receiptId;
    }

    using Strings for uint256;
    bool public open;
    string public baseURI;
    mapping(uint256 => string) private _tokenURIs;
    mapping (address => mapping(uint256 => BorrowerReceipt )) private _borrowerReceipt;
    mapping (address => mapping(uint256 => LenderReceipt )) private _lenderReceipt;

    address public _proxy;
    // uint256 public maxSupply;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721A(_name, _symbol) Ownable(msg.sender) {}

    function getBorrowerReceiptId(address nftContractAddress, uint256 tokenId)external view returns(BorrowerReceipt memory){
        return  _borrowerReceipt[nftContractAddress][tokenId];
    }

    function getLenderReceiptId(address nftContractAddress, uint256 tokenId)external view returns(LenderReceipt memory){
        return  _lenderReceipt[nftContractAddress][tokenId];
    }

    function mintReceipt(address to) internal  {
        _safeMint(to, 1);
    }

    function generateLenderReceipt(
        address nftContractAddress,
        uint256 tokenId,
        address lender
    ) external onlyProxyManager returns (uint256) {
        require(open, "Contract closed");
        mintReceipt(lender);
        uint256 nftId = _nextTokenId() - 1;
        _lenderReceipt[nftContractAddress][tokenId] = LenderReceipt(lender, nftId);

        return nftId;
    }

    function generateBorrowerReceipt(
        address nftContractAddress,
        uint256 tokenId,
        address borrower
    ) external onlyProxyManager returns (uint256) {
        require(open, "Contract closed");
        mintReceipt(borrower);
         uint256 nftId = _nextTokenId() - 1;
        _borrowerReceipt[nftContractAddress][tokenId] = BorrowerReceipt(borrower,nftId);

        return nftId;
    }

    function burnReceipt(uint256 _tokenId) external onlyProxyManager {
        _burn(_tokenId);
    }

    function setOpen(bool _open) external onlyOwner {
        open = _open;
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

    function setProxyManager(address newProxy) external onlyOwner {
        require(newProxy != address(0), "200:ZERO_ADDRESS");
        _proxy = newProxy;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenExist(uint256 id) external view returns (bool) {
        return _exists(id);
    }
}
