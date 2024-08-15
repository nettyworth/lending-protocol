// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Import necessary libraries and interfaces from OpenZeppelin
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ICryptoVault.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// CryptoVault contract that serves as a vault for ERC721 tokens
contract CryptoVault is
    Initializable,
    ERC1155Holder,
    ERC721Holder,
    Ownable,
    ReentrancyGuard
{
    mapping(address => mapping(uint256 => bool)) private assets; // Mapping to keep track of deposited ERC721 tokens

    mapping(address => mapping(uint256 => uint256)) public receipts;

    address public _proxy; // Address of the proxy contract used for access control

    // Event emitted when a user deposits an ERC721 token into the vault
    event Deposit(
        address indexed sender,
        address indexed tokenAddress,
        uint256 indexed tokenId
    );

    // Event emitted when a user withdraws an ERC721 token from the vault
    event Withdrawal(
        address indexed sender,
        address indexed tokenAddress,
        uint256 indexed tokenId
    );

    constructor() Ownable(msg.sender) {}

    // Function to deposit an ERC721 token into the vault
    function deposit(
        address tokenAddress,
        uint256 tokenId
    ) external onlyProxyManager {
        IERC721 token = IERC721(tokenAddress);
        require(
            token.ownerOf(tokenId) == msg.sender,
            "You are not the owner of this token"
        );

        token.safeTransferFrom(msg.sender, address(this), tokenId);
        assets[tokenAddress][tokenId] = true;

        emit Deposit(msg.sender, tokenAddress, tokenId);
    }

    // Function to withdraw an ERC721 token from the vault
    function withdraw(
        address tokenAddress,
        uint256 tokenId
    ) external onlyProxyManager {
        require(
            assets[tokenAddress][tokenId],
            "This token is not stored in the vault"
        );

        IERC721 token = IERC721(tokenAddress);
        require(
            token.ownerOf(tokenId) == address(this),
            "The vault does not own this token"
        );

        token.safeTransferFrom(address(this), msg.sender, tokenId);
        assets[tokenAddress][tokenId] = false;

        emit Withdrawal(msg.sender, tokenAddress, tokenId);
    }

    // Function to check if an ERC721 token is stored in the vault
    function isAssetStored(
        address tokenAddress,
        uint256 tokenId
    ) external view returns (bool) {
        return assets[tokenAddress][tokenId];
    }

    // Function to check if an ERC721 token is stored in the vault
    function attachReceiptToNFT(
        address tokenAddress,
        uint256 tokenId,
        uint256 receiptId
    ) external onlyProxyManager {
        // In the server side database, we need to save the reference receipt, tokenAddress and tokenID
        //That way the meetadata for the token can be set
        receipts[tokenAddress][tokenId] = receiptId;
    }

    // Modifier to restrict certain functions to the proxy manager (orchestrator)
    modifier onlyProxyManager() {
        require(
            _proxy == msg.sender,
            "Ownable: caller is not the proxy manager"
        );
        _;
    }

    // Function to set the proxy manager address
    function setProxyManager(address newProxy) external onlyOwner {
        require(newProxy != address(0), "ZERO_ADDRESS");
        _proxy = newProxy;
    }
}
