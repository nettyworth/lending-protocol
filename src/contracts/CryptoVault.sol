// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IReceipts.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

// CryptoVault contract that serves as a vault for ERC721 tokens
contract CryptoVault is ERC721Holder, Ownable {

    mapping(address => mapping(uint256 => address)) private _assets; // Mapping to keep track of deposited ERC721 tokens
    using SafeERC20 for IERC20;
    address public _proxy; // Address of the proxy contract used for access control
    address private _purposeproxy;

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

    constructor() Ownable(msg.sender){}

    function depositNftToEscrowAndERC20ToBorrower(
        address nftContract,
        uint256 tokenId,
        address currencyERC20,
        address lender,
        address borrower,
        uint256 loanAmount
        ) external onlyProxyManager  
        {

        IERC721 nft = IERC721(nftContract);
        IERC20 erc20Token = IERC20(currencyERC20);
        require(
            nft.ownerOf(tokenId) == borrower,
            "You are not the owner of this token"
        );
        require(nft.getApproved(tokenId)!= address(0) || nft.isApprovedForAll(borrower,address(this)),"Insufficent NFT Allowance/Wrong address allowance");
        require(erc20Token.allowance(lender,address(this)) >= loanAmount,"Insufficent Allowance");
        _assets[nftContract][tokenId] = borrower;
        nft.safeTransferFrom(borrower, address(this), tokenId);
        erc20Token.safeTransferFrom(lender, borrower, loanAmount);
        emit nftDepositToEscrow(borrower, nftContract, tokenId);
    }

    // Function to withdraw an ERC721 token from the vault
    function withdrawNftFromEscrowAndERC20ToLender(
        address nftContract,
        uint256 tokenId,
        address borrower,
        address lender,
        uint256 rePaymentAmount,
        uint256 computeAdminFee,
        address currencyERC20,
        address adminWallet
    ) external onlyProxyManager {

        IERC20 erc20Token = IERC20(currencyERC20);
        IERC721 token = IERC721(nftContract);

        require(
            _assets[nftContract][tokenId] != address(0),
            "This token is not stored in the vault"
        );
        require(_assets[nftContract][tokenId]== borrower,
        "Borrower is not the owner ");
        require(erc20Token != IERC20(address(0)), "Invalid ERC20 token address");
        require(erc20Token.allowance(borrower,address(this)) >= rePaymentAmount,"Insufficent Allowance");
        require(erc20Token.balanceOf(borrower) >= rePaymentAmount ,"Insufficent balance to payloan");
     
        require(
            token.ownerOf(tokenId) == address(this),
            "The vault does not own this token"
        );

        rePaymentAmount -= computeAdminFee;

        require(rePaymentAmount >= computeAdminFee, "Admin fee exceeds repayment");
        
        _assets[nftContract][tokenId] = address(0);
        erc20Token.safeTransferFrom(borrower, adminWallet, computeAdminFee);
        erc20Token.safeTransferFrom(borrower, lender, rePaymentAmount);
        token.safeTransferFrom(address(this),borrower, tokenId);

        emit nftWithdrawalFromEscrow(borrower, nftContract, tokenId);
    }
    
    // Function to withdraw an ERC721 token from the vault
    function withdrawNftFromEscrow(
      address nftContract,
        uint256 tokenId,
        address borrower
    ) external onlyProxyManager {

        IERC721 token = IERC721(nftContract);

        require(
            _assets[nftContract][tokenId] != address(0),
            "This token is not stored in the vault"
        );
        require(_assets[nftContract][tokenId]== borrower,
        "borrower is not the owner"); 
        require(
            token.ownerOf(tokenId) == address(this),
            "The vault does not own this token"
        );

        _assets[nftContract][tokenId] = address(0);
        token.safeTransferFrom(address(this), borrower, tokenId);
        emit nftWithdrawalFromEscrow(borrower, nftContract, tokenId);
    }

    // Function to withdraw an ERC721 token from the vault
    function withdrawNftFromEscrow(
        address nftContract,
        uint256 tokenId,
        address borrower,
        address lender
    ) external onlyProxyManager {

        IERC721 token = IERC721(nftContract);

        require(
            _assets[nftContract][tokenId] != address(0),
            "This token is not stored in the vault"
        );
        require(_assets[nftContract][tokenId]== borrower,
        "borrower is not the owner "); // added
        require(
            token.ownerOf(tokenId) == address(this),
            "The vault does not own this token"
        );

        _assets[nftContract][tokenId] = address(0);
        token.safeTransferFrom(address(this), lender, tokenId);
        emit nftWithdrawalFromEscrow(lender, nftContract, tokenId);
    }

    // Function to check if an ERC721 token is stored in the vault
    function AssetStoredOwner(
        address tokenAddress,
        uint256 tokenId
    ) external view returns (address) {
        return _assets[tokenAddress][tokenId];
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
    function purposeProxyManager(address newProxy) external onlyOwner {
        require(newProxy != address(0), "200:ZERO_ADDRESS");
        _purposeproxy = newProxy;
    }

    function setProxyManager() external onlyOwner {
        _proxy = _purposeproxy;
        _purposeproxy = address(0);
    } 

    function renounceOwnership() public view override onlyOwner {
    }
}