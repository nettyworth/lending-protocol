pragma solidity ^0.8.19;

import "./ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LoanReceipt is ERC721A, ReentrancyGuard, Ownable {
    struct BorrowerReceipt {
        uint256 loanIndex;
        uint256 amount;
        uint256 timestamp;
    }

    struct LenderReceipt {
        uint256 loanIndex;
        uint256 amount;
        uint256 timestamp;
    }

    using Strings for uint256;
    bool public open;
    string public baseURI;
    mapping(uint256 => string) private _tokenURIs;
    address public _proxy;
    uint256 public maxSupply;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721A(_name, _symbol) {}

    function mintReceipt(address to) internal {
        _safeMint(to, 1);
    }

    function generateReceipts(
        address lender
    ) external onlyProxyManager returns (uint256) {
        require(open, "Contract closed");
        mintReceipt(lender);
        return totalSupply();
    }

    function generateBorrowerReceipt(
        address borrower
    ) external onlyProxyManager returns (uint256) {
        require(open, "Contract closed");
        mintReceipt(borrower);
        return totalSupply();
    }

    function burnReceipt(uint256 _tokenId) external {
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
