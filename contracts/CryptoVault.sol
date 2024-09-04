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
    mapping(address => mapping(uint256 => address)) private assets; // Mapping to keep track of deposited ERC721 tokens

    mapping(address => mapping(uint256 => uint256)) public receipts;

    address public _proxy; // Address of the proxy contract used for access control

    // Event emitted when a user deposits an ERC721 token into the vault
    event nftDepositToEscrow(
        address indexed sender,
        address indexed tokenAddress,
        uint256 indexed tokenId
    );

    // Event emitted when a user withdraws an ERC721 token from the vault
    event nftWithdrawalFromEscrow(
        address indexed sender,
        address indexed tokenAddress,
        uint256 indexed tokenId
    );

    constructor() Ownable(msg.sender) {}

    // Function to deposit an ERC721 token into the vault
    function deposit(
        address borrower,
        address nftCollateralAddress,
        uint256 tokenId
    ) external onlyProxyManager {
        IERC721 nft = IERC721(nftCollateralAddress);
        require(
            nft.ownerOf(tokenId) == borrower,
            "You are not the owner of this token"
        );

        nft.safeTransferFrom(borrower, address(this), tokenId);
        assets[nftCollateralAddress][tokenId] = borrower;

        emit nftDepositToEscrow(borrower, nftCollateralAddress, tokenId);
    }

// //*************************************************************************************************************************************************************************************************************/
//     // function of NFTfi contracts

//     function _transferNftToAddress(address _nftContract, uint256 _nftId, address _borrower) internal returns (bool) {
//     // Try to call transferFrom()
//     bool transferFromSucceeded = _attemptTransferFrom(_nftContract, _nftId, _borrower);
//     if (transferFromSucceeded) {
//         return true;
//     } else {
//         // If transferFrom fails, try calling transfer()
//         bool transferSucceeded = _attemptTransfer(_nftContract, _nftId, _borrower);
//         return transferSucceeded;
//      }
//     }

//      function _attemptTransferFrom(address _nftContract, uint256 _nftId, address _recipient) internal returns (bool) {
  
//        _nftContract.call(abi.encodeWithSelector(IERC721(_nftContract).approve.selector, address(this), _nftId));

//         (bool success, ) = _nftContract.call(abi.encodeWithSelector(IERC721(_nftContract).transferFrom.selector, address(this), _recipient, _nftId));
//         return success;
//     }

//     function _attemptTransfer(address _nftContract, uint256 _nftId, address _recipient) internal returns (bool) {
      
//         (bool success, ) = _nftContract.call(abi.encodeWithSelector(ICryptoKittiesCore(_nftContract).transfer.selector, _recipient, _nftId));
//         return success;
//     }


//*************************************************************************************************************************************************************************************************************/



    // Function to withdraw an ERC721 token from the vault
    function withdraw(
        address nftColletralAddress,
        uint256 tokenId,
        address borrower
    ) external onlyProxyManager {
        require(
            assets[nftColletralAddress][tokenId] != address(0),
            "This token is not stored in the vault"
        );

        require(assets[nftColletralAddress][tokenId]== borrower,
        "Caller is not the owner "); // added by op

        IERC721 token = IERC721(nftColletralAddress);
        require(
            token.ownerOf(tokenId) == address(this),
            "The vault does not own this token"
        );
        // _transferNftToAddress(nftColletralAddress,tokenId,borrower);

        token.safeTransferFrom(address(this), msg.sender, tokenId);
        assets[nftColletralAddress][tokenId] = address(0);

        emit nftWithdrawalFromEscrow(msg.sender, nftColletralAddress, tokenId);
    }

    // Function to check if an ERC721 token is stored in the vault
    function AssetStoredOwner(
        address tokenAddress,
        uint256 tokenId
    ) external view returns (address) {
        return assets[tokenAddress][tokenId];
    }

    // Function to attach nft receipts
    function attachReceiptToNFT(
        address nftColletralAddress,
        uint256 tokenId,
        uint256 receiptId
    ) external onlyProxyManager {
        // In the server side database, we need to save the reference receipt, tokenAddress and tokenID
        //That way the meetadata for the token can be set
        receipts[nftColletralAddress][tokenId] = receiptId;
    }

       function unattachReceiptToNFT(
        address nftColletralAddress,
        uint256 tokenId,
        uint256 receiptId
    ) external onlyProxyManager {
        require(receipts[nftColletralAddress][tokenId] == receiptId, "Receipt id does not match");
        delete receipts[nftColletralAddress][tokenId];
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
abstract contract ICryptoKittiesCore {
    function transfer(address _to, uint256 _tokenId) external virtual;
}