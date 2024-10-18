// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./utils/ERC721A.sol";

contract LoanReceipt is ERC721A, Ownable {
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
    bool private _purposeOpen; // Audit fix # 11

    string public baseURI;
    mapping(uint256 => string) private _tokenURIs;
    mapping (address => mapping(uint256 => BorrowerReceipt )) private _borrowerReceipt;
    mapping (address => mapping(uint256 => LenderReceipt )) private _lenderReceipt;

    address public _proxy;
    address private _purposeproxy; // Audit fix # 11


    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721A(_name, _symbol) Ownable(msg.sender) {}

    function getBorrowerReceiptId(address nftContractAddress, uint256 tokenId)external view returns(uint256 borrowerReceiptId, address borrowerAddress){
        borrowerReceiptId = _borrowerReceipt[nftContractAddress][tokenId].receiptId;
        borrowerAddress = _borrowerReceipt[nftContractAddress][tokenId].borrower;
        return  (borrowerReceiptId, borrowerAddress );
    }

    function getLenderReceiptId(address nftContractAddress, uint256 tokenId)external view returns(uint256 lenderReceiptId, address lenderAddress){
        lenderReceiptId = _lenderReceipt[nftContractAddress][tokenId].receiptId;
        lenderAddress = _lenderReceipt[nftContractAddress][tokenId].lender;
        return  (lenderReceiptId, lenderAddress );
    }

    function _mintReceipt(address to) internal  {
        _safeMint(to, 1);
    }

    function generateLenderReceipt(
        address nftContractAddress,
        uint256 tokenId,
        address lender
    ) external onlyProxyManager returns (uint256) {
        require(open, "Contract closed");
        _mintReceipt(lender);
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
        _mintReceipt(borrower);
         uint256 nftId = _nextTokenId() - 1;
        _borrowerReceipt[nftContractAddress][tokenId] = BorrowerReceipt(borrower,nftId);

        return nftId;
    }

    function burnReceipt(uint256 _tokenId) external onlyProxyManager {
        _burn(_tokenId);
    }

    function purposeSetOpen(bool _open) external onlyOwner {
        _purposeOpen = _open;
    }// Audit fix # 11

    function SetOpen() external onlyOwner {
        open = _purposeOpen;
        _purposeOpen = false;
    }// Audit fix # 11

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

    function purposeProxyManager(address newProxy) external onlyOwner {
        require(newProxy != address(0), "200:ZERO_ADDRESS");
        _purposeproxy = newProxy;
    }// Audit fix # 11

    function setProxyManager() external onlyOwner {
        _proxy = _purposeproxy;
        _purposeproxy = address(0);
    }// Audit fix # 11

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenExist(uint256 id) external view returns (bool) {
        return _exists(id);
    }
    // audit fix 12
    function renounceOwnership() public view override onlyOwner {
    }
}
