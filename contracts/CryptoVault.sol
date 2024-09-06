// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./interfaces/IReceipts.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// CryptoVault contract that serves as a vault for ERC721 tokens
contract CryptoVault is ERC721Holder, Ownable {

    mapping(address => mapping(uint256 => address)) private assets; // Mapping to keep track of deposited ERC721 tokens

    // mapping(address => mapping(uint256 => uint256)) public receipts;
    using SafeERC20 for IERC20;
    ReceiptInterface public _ireceipts;
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
    // function deposit(
    //     address borrower,
    //     address nftCollateralAddress,
    //     uint256 tokenId
    // ) internal {
    //     IERC721 nft = IERC721(nftCollateralAddress);
    //     require(
    //         nft.ownerOf(tokenId) == borrower,
    //         "You are not the owner of this token"
    //     );

    //     nft.safeTransferFrom(borrower, address(this), tokenId);
    //     assets[nftCollateralAddress][tokenId] = borrower;

    //     // emit nftDepositToEscrow(borrower, nftCollateralAddress, tokenId);
    // }

    function setReceiptContract(address _receiptContract) public onlyOwner {
        require(_receiptContract != address(0), "Invalid address");
        // receiptContract = _receiptContract;
        _ireceipts = ReceiptInterface(_receiptContract);
    }


// need to be updated
    function depositNftToEscrowAndERC20ToBorrower(
        address nftContract,
        uint256 tokenId,
        address currencyERC20,
        address lender,
        address borrower,
        uint256 loanAmount
        ) external onlyProxyManager  
        // returns(uint256 receiptIdBorrower, uint256 receiptIdLender)
        {

        IERC721 nft = IERC721(nftContract);
        require(
            nft.ownerOf(tokenId) == borrower,
            "You are not the owner of this token"
        );

        // Validate the provided signature (server-side validation)
        // Transfer the specified ERC721 token to the vault
        // deposit(_borrower,_contract, _tokenId);


        nft.safeTransferFrom(borrower, address(this), tokenId);
        assets[nftContract][tokenId] = borrower;
        // // Transfer the ERC20 amount from the borrower to the vault
        IERC20 erc20Token = IERC20(currencyERC20);
        erc20Token.safeTransferFrom(lender, borrower, loanAmount);
        // Generate promissory note nft to lender
        // receiptIdBorrower = _ireceipts.generateBorrowerReceipt(nftContract,tokenId,borrower);
        // _icryptoVault.attachReceiptToNFT(_contract, _tokenId, receiptIdBorrower);
        // receiptIdLender = _ireceipts.generateLenderReceipt(nftContract,tokenId,lender);
        // _icryptoVault.attachReceiptToNFT(_contract, _tokenId, receiptIdLender);
        emit nftDepositToEscrow(borrower, nftContract, tokenId);

        // return (receiptIdBorrower,receiptIdLender);
        // return (1,2);

    }

    // Function to withdraw an ERC721 token from the vault
    function withdrawNftFromEscrowAndERC20ToLender(
      address nftContract,
        uint256 tokenId,
        address borrower,
        address lender,
        uint256 remainingAmount,
        address currencyERC20
    ) external onlyProxyManager {
        require(
            assets[nftContract][tokenId] != address(0),
            "This token is not stored in the vault"
        );
        require(assets[nftContract][tokenId]== borrower,
        "Caller is not the owner "); // added
        IERC20 erc20Token = IERC20(currencyERC20);
        require(erc20Token != IERC20(address(0)), "You have to pay loan via native currency");
        require(erc20Token.balanceOf(borrower) >= remainingAmount ,"Insufficent balance to payloan");
        IERC721 token = IERC721(nftContract);
        require(
            token.ownerOf(tokenId) == address(this),
            "The vault does not own this token"
        );
        // _transferNftToAddress(nftColletralAddress,tokenId,borrower);

        erc20Token.safeTransferFrom(borrower, lender, remainingAmount);

        token.safeTransferFrom(address(this),borrower, tokenId);

        assets[nftContract][tokenId] = address(0);

        emit nftWithdrawalFromEscrow(borrower, nftContract, tokenId);
    }
    
        // Function to withdraw an ERC721 token from the vault
    function withdrawNftFromEscrow(
      address nftContract,
        uint256 tokenId,
        address borrower
    ) external onlyProxyManager {
        require(
            assets[nftContract][tokenId] != address(0),
            "This token is not stored in the vault"
        );
        require(assets[nftContract][tokenId]== borrower,
        "Caller is not the owner "); // added

        IERC721 token = IERC721(nftContract);
        require(
            token.ownerOf(tokenId) == address(this),
            "The vault does not own this token"
        );
        // _transferNftToAddress(nftColletralAddress,tokenId,borrower);

        token.safeTransferFrom(address(this), borrower, tokenId);

        assets[nftContract][tokenId] = address(0);

        emit nftWithdrawalFromEscrow(borrower, nftContract, tokenId);
    }

          // Function to withdraw an ERC721 token from the vault
    function withdrawNftFromEscrow(
      address nftContract,
        uint256 tokenId,
        address borrower,
        address lender
    ) external onlyProxyManager {
        require(
            assets[nftContract][tokenId] != address(0),
            "This token is not stored in the vault"
        );
        require(assets[nftContract][tokenId]== borrower,
        "Caller is not the owner "); // added

        IERC721 token = IERC721(nftContract);
        require(
            token.ownerOf(tokenId) == address(this),
            "The vault does not own this token"
        );
        // _transferNftToAddress(nftColletralAddress,tokenId,borrower);

        token.safeTransferFrom(address(this), lender, tokenId);

        assets[nftContract][tokenId] = address(0);

        emit nftWithdrawalFromEscrow(lender, nftContract, tokenId);
    }
    // Function to check if an ERC721 token is stored in the vault
    function AssetStoredOwner(
        address tokenAddress,
        uint256 tokenId
    ) external view returns (address) {
        return assets[tokenAddress][tokenId];
    }

    // Function to attach nft receipts
    // function attachReceiptToNFT(
    //     address nftColletralAddress,
    //     uint256 tokenId,
    //     uint256 receiptId
    // ) external onlyProxyManager {
    //     // In the server side database, we need to save the reference receipt, tokenAddress and tokenID
    //     //That way the meetadata for the token can be set
    //     receipts[nftColletralAddress][tokenId] = receiptId;
    // }

    //    function unattachReceiptToNFT(
    //     address nftColletralAddress,
    //     uint256 tokenId,
    //     uint256 receiptId
    // ) external onlyProxyManager {
    //     require(receipts[nftColletralAddress][tokenId] == receiptId, "Receipt id does not match");
    //     delete receipts[nftColletralAddress][tokenId];
    // }

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