// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity ^0.8.24;
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFTExample is ERC721A, ReentrancyGuard, Ownable {
    using Strings for uint256;
    // Public attributes for Manageable interface
    string public project;
    uint256 public maxSupply;
    bool public open;
    string public baseURI;
    mapping(uint256 => string) private _tokenURIs;

    constructor(
        string memory _project,
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply
    ) ERC721A(_name, _symbol) Ownable(msg.sender) {
        project = _project;
        maxSupply = _maxSupply;
    }

    function airdrop(address to, uint256 amount) public nonReentrant onlyOwner {
        require(_totalMinted() + amount <= maxSupply, "Invalid amount");
        _safeMint(to, amount);
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

    function setTokenURI(uint256 id, string memory newURL) external onlyOwner {
        require(bytes(newURL).length > 0, "New URL Invalid");
        require(_exists(id), "Invalid Token");
        _tokenURIs[id] = newURL;
    }

    function setMaxSupply(uint256 _totalSupply) external onlyOwner {
        require(_totalSupply >= _totalMinted(), "Total supply too low");
        maxSupply = _totalSupply;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
