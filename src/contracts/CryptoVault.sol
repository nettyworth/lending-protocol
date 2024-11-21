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

    mapping(address => mapping(uint256 => bytes32)) private _assetsHash; // Mapping to keep track of deposited ERC721 token ID's via Keccak hash
    mapping(address => mapping(uint256 =>  uint256[])) private _assets; // Mapping to keep track of deposited ERC721 token ID's

    using SafeERC20 for IERC20;
    address public _proxy; // Address of the proxy contract used for access control
    address private _proposeproxy;

    // Event emitted when a user deposits an ERC721 token into the vault
    event nftDepositToEscrow(
        address indexed sender,
        address indexed tokenAddress,
        uint256[]  tokenIds
    );

    // Event emitted when a user withdraws an ERC721 token from the vault
    event nftWithdrawalFromEscrow(
        address indexed sender,
        address indexed tokenAddress,
        uint256[] tokenIds
    );

    constructor() Ownable(msg.sender){}

    function safeBatchTransfer(
        IERC721 erc721Contract,
        address from,
        address to,
        uint256[] calldata tokenIds
    ) public {

        uint256 length = tokenIds.length;
        _checkOwner(erc721Contract,from,tokenIds);

        for (uint256 i; i < length; ) {
            uint256 tokenId = tokenIds[i];
            erc721Contract.safeTransferFrom(from, to, tokenId);
            unchecked {
                i++;
            }
        }
       
    }

    function _checkOwner(IERC721 erc721Contract, address owner ,uint256[] calldata tokenIds) internal view{
         uint256 length = tokenIds.length;
            for (uint256 i; i < length; ) {
            uint256 tokenId = tokenIds[i];
            address _owner = erc721Contract.ownerOf(tokenId);
            require(owner == _owner,"Invalid Owner of Token ID");
            unchecked {
                i++;
            }
        }
    }

    function depositNftToEscrowAndERC20ToBorrower(
        address nftContract,
        uint256 loanId,
        uint256[] calldata tokenIds,
        address currencyERC20,
        address lender,
        address borrower,
        uint256 loanAmount
    ) external onlyProxyManager  
        {

        IERC721 nft = IERC721(nftContract);
        IERC20 erc20Token = IERC20(currencyERC20);

        require(nft.isApprovedForAll(borrower, address(this)), "Insufficent NFT Allowance/Wrong address allowance");
        require(erc20Token.allowance(lender, address(this)) >= loanAmount, "Insufficent Allowance");

        _assets[nftContract][loanId]= tokenIds; 
        bytes32 _tokenIds = _bytesconvertion(tokenIds);
        _assetsHash[nftContract][loanId] = _tokenIds; 
        safeBatchTransfer(nft, borrower, address(this), tokenIds);
        erc20Token.safeTransferFrom(lender, borrower, loanAmount);
        emit nftDepositToEscrow(borrower, nftContract, tokenIds);
    }

    function _bytesconvertion(uint256[] calldata tokenIds) internal pure returns(bytes32 ){
       return keccak256(abi.encode(tokenIds));
    }

    // Function to withdraw an ERC721 token from the vault
    function withdrawNftFromEscrowAndERC20ToLender(
        address nftContract,
        uint256 loanId,
        uint256[] calldata tokenIds,
        address borrower,
        address lender,
        uint256 rePaymentAmount,
        uint256 computeAdminFee,
        address currencyERC20,
        address adminWallet
    ) external onlyProxyManager {

        IERC20 erc20Token = IERC20(currencyERC20);
        IERC721 token = IERC721(nftContract);
        bytes32 _tokenIds = _bytesconvertion(tokenIds);

        require(
            _assetsHash[nftContract][loanId] != 0,  
            "This token's are not stored in the vault"
        );
        require(_assetsHash[nftContract][loanId]== _tokenIds,  
        "Invalid NFT ID's ");
        require(erc20Token != IERC20(address(0)), "Invalid ERC20 token address");
        require(erc20Token.allowance(borrower, address(this)) >= rePaymentAmount,"Insufficent Allowance");
        require(erc20Token.balanceOf(borrower) >= rePaymentAmount ,"Insufficent balance to payloan");
     
        rePaymentAmount -= computeAdminFee;

        require(rePaymentAmount >= computeAdminFee, "Admin fee exceeds repayment");
        
        delete _assetsHash[nftContract][loanId];  
        delete _assets[nftContract][loanId];  
        erc20Token.safeTransferFrom(borrower, adminWallet, computeAdminFee);
        erc20Token.safeTransferFrom(borrower, lender, rePaymentAmount);
        safeBatchTransfer(token, address(this), borrower, tokenIds);

        emit nftWithdrawalFromEscrow(borrower, nftContract, tokenIds);
    }
    
    // Function to withdraw an ERC721 token from the vault
    function withdrawNftFromEscrow(
        address nftContract,
        uint256 loanId,
        uint256[] calldata tokenIds,
        address lender
    ) external onlyProxyManager {

        IERC721 token = IERC721(nftContract);
        bytes32 _tokenIds = _bytesconvertion(tokenIds);


        require(
            _assetsHash[nftContract][loanId] != 0,
            "This token is not stored in the vault"
        ); 
        require(_assetsHash[nftContract][loanId]== _tokenIds,
        "Invalid NFT ID's "); 

        delete _assetsHash[nftContract][loanId]; 
        delete _assets[nftContract][loanId];  

        safeBatchTransfer(token,address(this),lender, tokenIds);

        emit nftWithdrawalFromEscrow(lender, nftContract, tokenIds);
    }

    // Function to check if an ERC721 token is stored in the vault
    function AssetStoredOwner(
        address nftContract,
        uint256 loanId
    ) external view returns (uint256[] memory) {
        return _assets[nftContract][loanId];
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
    function proposeProxyManager(address newProxy) external onlyOwner {
        require(newProxy != address(0), "200:ZERO_ADDRESS");
        _proposeproxy = newProxy;
    }

    function setProxyManager() external onlyOwner {
        require(_proposeproxy != address(0), "200:ZERO_ADDRESS");
        _proxy = _proposeproxy;
        _proposeproxy = address(0);
    } 

    function renounceOwnership() public view override onlyOwner {
    }
}