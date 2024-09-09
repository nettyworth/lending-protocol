// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICryptoVault.sol";
import "./interfaces/ILoanManager.sol";
import "./interfaces/IReceipts.sol";
import "./interfaces/IwhiteListCollection.sol";
import "./library/SignatureUtils.sol";


contract NettyWorthProxy is ReentrancyGuard, Initializable {

    using SafeERC20 for IERC20;
    using Address for address;

    address public vault;
    address public loanManager;
    address public receiptContract;
    address public whiteListContract;
    address public _owner;

    ICryptoVault _icryptoVault;
    ILoanManager _iloanManager;
    ReceiptInterface _ireceipts;
    IwhiteListCollection _iwhiteListCollection;
    
    event LoanRepaid(
        uint256 indexed loanId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address  borrower,
        address  lender,
        uint256 repayment,
        address erc20Address,
        bool isPaid
    );

    event LoanForClosed(
        uint256 indexed loanId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address  borrower,
        address  lender,
        bool isDefault
    );

    mapping (address => mapping (uint256 => bool)) private _nonceUsedForUser;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not the owner");
        _;
    }

    function initialize(
        address _vault,
        address _loanManager,
        address _receiptContract,
        address _iwhiteListContract
    ) external initializer {
        _owner = msg.sender;
        setVault(_vault);
        setLoanManager(_loanManager);
        setReceiptContract(_receiptContract);
        setWhiteListContract(_iwhiteListContract);
    }

    function setWhiteListContract(address _whiteList) public onlyOwner {
        require(_whiteList != address(0), "Invalid address");
        whiteListContract = _whiteList;
        _iwhiteListCollection = IwhiteListCollection(whiteListContract);
    }


    function setVault(address _vault) public onlyOwner {
        require(_vault != address(0), "Invalid address");
        vault = _vault;
        _icryptoVault = ICryptoVault(_vault);
    }

    function setLoanManager(address _loanManager) public onlyOwner {
        require(_loanManager != address(0), "Invalid address");
        loanManager = _loanManager;
        _iloanManager = ILoanManager(loanManager);
    }

    function setReceiptContract(address _receiptContract) public onlyOwner {
        require(_receiptContract != address(0), "Invalid address");
        receiptContract = _receiptContract;
        _ireceipts = ReceiptInterface(receiptContract);
    }

//*****************************************************************************************************************************//
//*****************************************************************************************************************************//

// [2,"0xF7c72F54eD6efbdF3fd076527E312E5652Aa148b","0x430d082e46091173B8A4f9f48752e16e3A3a4c62","0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",1000,200,1728187189,1234]
    // Accept Offer parameters
    //     uint256 tokenId;           
    //     address nftContractAddress;
    //     address erc20TokenAddress;
    //     address lender;
    //     address borrower;
    //     uint256 loanAmount;
    //     uint256 interestRate;
    //     uint256 loanDuration;
    //     uint256 nonce;

//[1,"0xF7c72F54eD6efbdF3fd076527E312E5652Aa148b","0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",2000000000000000000,200,1728187189,1234]
    function _deposit( address collectionAddress,
            uint256 tokenId,
            address erc20TokenAddress,
            address lender,
            address borrower,
            uint256 loanAmount) internal {
          _icryptoVault.depositNftToEscrowAndERC20ToBorrower( 
            collectionAddress,
            tokenId,
            erc20TokenAddress,
            lender,
            borrower,
            loanAmount
        );
    }

    function _acceptOffer(address collectionAddress,
            uint256 tokenId,
            address borrower,
            address lender,
            uint256 loanAmount,
            uint256 interestRate,
            uint256 loanDuration,
            address erc20TokenAddress,
            uint256 nonce) internal returns(uint256 _receiptIdBorrower, uint256 _receiptIdLender){

        (ILoanManager.Loan memory loan,uint256 _loanId) = _iloanManager.getLoan(
            collectionAddress,
            tokenId,
            borrower,
            nonce
        );

        require(!loan.isPaid, "Loan offer is closed");
        require(!loan.isApproved, "Loan offer is already approved");
        
        _iloanManager.createLoan(
            collectionAddress,
            tokenId,
            borrower,
            lender,
            loanAmount,
            interestRate,
            loanDuration,
            erc20TokenAddress,
            nonce
        );

        _iloanManager.updateIsApproved(_loanId, true);

        _deposit( 
            collectionAddress,
            tokenId,
            erc20TokenAddress,
            lender,
            borrower,
            loanAmount
        );

        _receiptIdBorrower = _ireceipts.generateBorrowerReceipt(collectionAddress,tokenId,borrower);
        _receiptIdLender = _ireceipts.generateLenderReceipt(collectionAddress,tokenId,lender);

        return (_receiptIdBorrower, _receiptIdLender);
    }

 function acceptLoanRequest(
        bytes calldata acceptRequestSignature,
        SignatureUtils.LoanRequest calldata loanRequest
    ) external nonReentrant returns(uint256 receiptIdBorrower, uint256 receiptIdLender) {

        // require(msg.sender == loanOffer.borrower || msg.sender == loanOffer.lender ,"Unauthorized sender");

        _sanityCheckAcceptOffer(
            loanRequest.nftContractAddress,
            msg.sender, //loanOffer.lender,
            loanRequest.borrower,
            loanRequest.loanDuration,
            loanRequest.nonce
        );
     
        // if(loanOffer.borrower == msg.sender){
        //     require(
        //         SignatureUtils.validateSignatureApprovalOffer(
        //             acceptOfferSignature,
        //             loanOffer
        //         ),
        //         "Invalid lender signature"
        //     );
        // }
        // if(loanOffer.lender == msg.sender){
            require(
                SignatureUtils.validateRequestLoanSignature(
                    acceptRequestSignature,
                    loanRequest
                ),
                "Invalid borrower signature"
            );
        // }

       (receiptIdBorrower, receiptIdLender) = _acceptOffer(loanRequest.nftContractAddress,
            loanRequest.tokenId,
            loanRequest.borrower,
            msg.sender,//loanRequest.lender,
            loanRequest.loanAmount,
            loanRequest.interestRate,
            loanRequest.loanDuration,
            loanRequest.erc20TokenAddress,
            loanRequest.nonce
        );

        // receiptIdBorrower = _ireceipts.generateBorrowerReceipt(loanOffer.nftContractAddress,loanOffer.tokenId,loanOffer.borrower);
        // receiptIdLender = _ireceipts.generateLenderReceipt(loanOffer.nftContractAddress,loanOffer.tokenId,loanOffer.lender);

        return(receiptIdBorrower, receiptIdLender);
    }

    function acceptLoanOffer(
        bytes calldata acceptOfferSignature,
        SignatureUtils.LoanOffer calldata loanOffer
    ) external nonReentrant returns(uint256 receiptIdBorrower, uint256 receiptIdLender ) {

        require(msg.sender == loanOffer.borrower || msg.sender == loanOffer.lender ,"Unauthorized sender");

        _sanityCheckAcceptOffer(
            loanOffer.nftContractAddress,
            loanOffer.lender,
            loanOffer.borrower,
            loanOffer.loanDuration,
            loanOffer.nonce
        );
     
        // if(loanOffer.borrower == msg.sender){
            require(
                SignatureUtils.validateSignatureApprovalOffer(
                    acceptOfferSignature,
                    loanOffer
                ),
                "Invalid lender signature"
            );
        // }
        // else if(loanOffer.lender ==msg.sender){
        //     require(
        //         SignatureUtils.validateRequestLoanSignature(
        //             acceptOfferSignature,
        //             loanOffer
        //         ),
        //         "Invalid borrower signature"
        //     );
        // }

       (receiptIdBorrower, receiptIdLender) = _acceptOffer(loanOffer.nftContractAddress,
            loanOffer.tokenId,
            loanOffer.borrower,
            loanOffer.lender,
            loanOffer.loanAmount,
            loanOffer.interestRate,
            loanOffer.loanDuration,
            loanOffer.erc20TokenAddress,
            loanOffer.nonce);

        // receiptIdBorrower = _ireceipts.generateBorrowerReceipt(loanOffer.nftContractAddress,loanOffer.tokenId,loanOffer.borrower);
        // receiptIdLender = _ireceipts.generateLenderReceipt(loanOffer.nftContractAddress,loanOffer.tokenId,loanOffer.lender);

        return(receiptIdBorrower, receiptIdLender);
    }


    function acceptLoanCollectionOffer(
        // bytes calldata acceptOfferSignature,
        SignatureUtils.LoanCollectionOffer calldata loanCollectionOffer,
        uint256 tokenId
    ) external nonReentrant returns(uint256 receiptIdBorrower, uint256 receiptIdLender ) {
        IERC721 nft = IERC721(loanCollectionOffer.collectionAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Current caller is not the owner of NFT");

        _sanityCheckAcceptOffer(loanCollectionOffer.collectionAddress,loanCollectionOffer.lender,msg.sender,loanCollectionOffer.loanDuration,loanCollectionOffer.nonce);

        // require(
        //         SignatureUtils.validateLoanCollectionOfferSignature(
        //             acceptOfferSignature,
        //             loanCollectionOffer
        //         ),
        //         "Invalid lender signature"
        //     );

       (receiptIdBorrower, receiptIdLender) = _acceptOffer(loanCollectionOffer.collectionAddress,
            tokenId,
            msg.sender,
            loanCollectionOffer.lender,
            loanCollectionOffer.loanAmount,
            loanCollectionOffer.interestRate,
            loanCollectionOffer.loanDuration,
            loanCollectionOffer.erc20TokenAddress,
            loanCollectionOffer.nonce);

        return(receiptIdBorrower, receiptIdLender);
    }





//*****************************************************************************************************************************//
//*****************************************************************************************************************************//

    function payBackLoan(uint256 _loanId, address erc20Token) external nonReentrant returns (bool){
        ILoanManager.Loan memory loan = _iloanManager.getLoanById(_loanId);
        require(loan.currencyERC20 == erc20Token, "Currency Invalid");
        uint256 remainingAmount = _iloanManager.getPayoffAmount(_loanId);

        (uint256 _borrowerReceiptId,) = _ireceipts.getBorrowerReceiptId(loan.nftContract, loan.tokenId);
        (uint256 _lenderReceiptId,) = _ireceipts.getLenderReceiptId(loan.nftContract, loan.tokenId);
        _sanityCheckPayBack(loan, _lenderReceiptId, _borrowerReceiptId);
        _icryptoVault.withdrawNftFromEscrowAndERC20ToLender(
            loan.nftContract,
            loan.tokenId,
            loan.borrower,
            loan.lender,
            remainingAmount,
            erc20Token
        );
        _ireceipts.burnReceipt(_lenderReceiptId);
        _ireceipts.burnReceipt(_borrowerReceiptId);
        
        _iloanManager.updateIsPaid(_loanId, true);

        emit LoanRepaid(
            _loanId,
            loan.nftContract,
            loan.tokenId,
            loan.borrower,
            loan.lender,
            remainingAmount,
            loan.currencyERC20,
            loan.isPaid
        );

    return true;
    }

    function forCloseLoan(uint256 _loanId) external  nonReentrant returns(bool){
        ILoanManager.Loan memory loan = _iloanManager.getLoanById(_loanId);
        
        require(block.timestamp >= loan.loanDuration,"User is not default yet::");
        
        require(!loan.isPaid, "Loan Paid");
        require(!loan.isDefault , "Already Claimed");
        
        (uint256 _borrowerReceiptId,) = _ireceipts.getBorrowerReceiptId(loan.nftContract, loan.tokenId);
        (uint256 _lenderReceiptId,) = _ireceipts.getLenderReceiptId(loan.nftContract, loan.tokenId);

        require(_ireceipts.tokenExist(_lenderReceiptId), "Receipt does not exist");
        require(_ireceipts.tokenExist(_borrowerReceiptId), "Receipt does not exist");

        address lender = _ireceipts.ownerOf(_lenderReceiptId);  
        address borrower = _ireceipts.ownerOf(_borrowerReceiptId); 
        
        require(loan.borrower == borrower, "Invalid borrower");
                                                
        require(loan.lender == lender && lender == msg.sender, "You are not the lender");
                    
        _iloanManager.updateIsDefault(_loanId, true);

        _icryptoVault.withdrawNftFromEscrow(loan.nftContract,loan.tokenId ,loan.borrower, msg.sender);

        _ireceipts.burnReceipt(_lenderReceiptId);
        _ireceipts.burnReceipt(_borrowerReceiptId);

        emit LoanForClosed(
        _loanId,
        loan.nftContract,
        loan.tokenId,
        loan.borrower,
        loan.lender,
        loan.isDefault
        );

    return true;
    } 

    function _sanityCheckPayBack(ILoanManager.Loan memory loan, uint256 _lenderReceiptId,uint256 _borrowerReceiptId) internal view {
        require(loan.isApproved, "Loan offer not approved");
        require(!loan.isDefault,"borrower is defaulter now");
        require(!loan.isPaid, "Loan is Paid");
        require(loan.lender != address(0), "Loan is not assigned to a lender");
        require(_ireceipts.tokenExist(_lenderReceiptId), "Receipt does not exist");
        require(_ireceipts.tokenExist(_borrowerReceiptId), "Receipt does not exist");
        address lender = _ireceipts.ownerOf(_lenderReceiptId);  
        address borrower = _ireceipts.ownerOf(_borrowerReceiptId); 
        require(loan.borrower == msg.sender && borrower == msg.sender, "caller is not borrower");
        require(loan.lender == lender, "Invalid Lender");
    }

    function _sanityCheckAcceptOffer(address nftContractAddress, address lender, address borrower,uint256 loanDuration, uint256 nonce) internal {
        require(vault != address(0), "Vault address not set");

        require(_iwhiteListCollection.isWhiteList(nftContractAddress), "Collection is not White Listed");

        require(loanManager != address(0), "Loan manager address not set");

        require(receiptContract != address(0), "Receipt contract address not set");

        require(loanDuration > block.timestamp,"Loan duration must b greater than current timestamp");

        require(!_nonceUsedForUser[lender][nonce] && !_nonceUsedForUser[borrower][nonce], "Offer nonce invalid");
        _nonceUsedForUser[lender][nonce] = true;
        _nonceUsedForUser[borrower][nonce] = true;

    }


}



