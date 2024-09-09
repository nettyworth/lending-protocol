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
        _iwhiteListCollection = IwhitelistCollection(whiteListContract);
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

//     function approveLoan(
//         uint256 tokenId,
//         address nftContractAddress,
//         address erc20TokenAddrss,
//         uint256 loanAmount,
//         uint256 interestRate,
//         uint256 loanDuration,
//         address lender,
//         address borrower
//     ) external nonReentrant {
//         require(vault != address(0), "Vault address not set");
//         require(loanManager != address(0), "Loan manager address not set");
//         require(receiptContract != address(0), "Receipt contract address not set");
//         ILoanManager.LoanData memory _data = ILoanManager.LoanData(nftContractAddress,tokenId,borrower,lender,loanAmount,interestRate,loanDuration,erc20TokenAddrss);
     

//         ILoanManager.Loan memory loan = _iloanManager.getLoan(
//             nftContractAddress,
//             tokenId,
//             borrower
//         );
//         //   ILoanManager.Loan memory loan = _iloanManager.getLoan(
         
//         require(!loan.isClosed, "Loan offer is closed");
//         require(!loan.isApproved, "Loan offer is already approved");

//         _iloanManager.createLoan(
//             _data._contract,
//             _data._tokenId,
//             _data._borrower,
//             _data._lender,
//             _data._loanAmount,
//             _data._interestRate,
//             _data._loanDuration,
//             _data._erc20Token      
//         );

//         _depositNftToEscrowAndERC20ToBorrower( 
//             nftContractAddress,
//             tokenId,
//             erc20TokenAddrss,
//              lender,
//              loanAmount
//             );

//         loan.isApproved =  true ;
// }



    // function getLoanData (
    //     uint256 tokenId,
    //     address nftContractAddress,
    //     address erc20TokenAddrss,
    //     uint256 loanAmount,
    //     uint256 interestRate,
    //     uint256 loanDuration,
    //     address lender,
    //     uint256 nonce,
    //     address borrower)internal pure returns (ILoanManager.LoanData memory){

    //     ILoanManager.LoanData memory _data = ILoanManager.LoanData(nftContractAddress,tokenId,borrower,lender,loanAmount,interestRate,loanDuration,erc20TokenAddrss,nonce);
    //         return _data;
    //     }


//*****************************************************************************************************************************//
//*****************************************************************************************************************************//
   
    // function acceptLoanOffer(
    //     // bytes calldata acceptOfferSignature,
    //     uint256 tokenId,
    //     address nftContractAddress,
    //     address erc20TokenAddress,
    //     uint256 loanAmount,
    //     uint256 interestRate,
    //     uint256 loanDuration,
    //     address lender,
    //     uint256 nonce,
    //     address borrower
    //     // SignatureUtils.LoanOffer memory _loanOffer
    // ) external nonReentrant returns(uint256 receiptIdBorrower, uint256 receiptIdLender ){
    //     require(vault != address(0), "Vault address not set");
    //     require(loanManager != address(0), "Loan manager address not set");
    //     require(receiptContract != address(0), "Receipt contract address not set");
    //     require(msg.sender == borrower || msg.sender == lender ,"Unauthorized sender");
    //     // require(!_nonceUsedForUser[msg.sender][nonce], "Nonce already used");
    //     // _nonceUsedForUser[msg.sender][nonce] = true;
    //     require(!_nonceUsedForUser[lender][nonce] && !_nonceUsedForUser[borrower][nonce], "Offer nonce invalid");
    //     _nonceUsedForUser[lender][nonce] = true;
    //     _nonceUsedForUser[borrower][nonce] = true;

    //     ILoanManager.LoanData memory data = ILoanManager.LoanData(
    //         nftContractAddress,
    //         tokenId,
    //         borrower,
    //         lender,
    //         loanAmount,
    //         interestRate,
    //         loanDuration,
    //         erc20TokenAddress,
    //         nonce
    //     );      

    //     // if(msg.sender == borrower){
    //     //     require(
    //     //         SignatureUtils.validateSignatureApprovalOffer(
    //     //             acceptOfferSignature,
    //     //             data._tokenId,
    //     //             data._contract,
    //     //             data._erc20Token,
    //     //             data._loanAmount,
    //     //             data._interestRate,
    //     //             data._loanDuration,
    //     //             data._lender,
    //     //             data._nonce,
    //     //             data._borrower
    //     //         ),
    //     //         "Invalid lender signature"
    //     //     );
    //     // }
    //     // else if(msg.sender == lender){
    //     //     require(
    //     //         SignatureUtils.validateRequestLoanSignature(
    //     //             acceptOfferSignature,
    //     //             data._tokenId,
    //     //             data._contract,
    //     //             data._erc20Token,
    //     //             data._loanAmount,
    //     //             data._interestRate,
    //     //             data._loanDuration,
    //     //             data._nonce,
    //     //             data._borrower
    //     //         ),
    //     //         "Invalid borrower signature"
    //     //     );
    //     // }
    //     (ILoanManager.Loan memory loan,) = _iloanManager.getLoan(
    //         data._contract,
    //         data._tokenId,
    //         data._borrower,
    //         data._nonce
    //     );
    //     require(!loan.isPaid, "Loan offer is closed");

    //     require(!loan.isApproved, "Loan offer is already approved");

    //     loan.isApproved =  true;

    //     _iloanManager.createLoan(
    //         data._contract,
    //         data._tokenId,
    //         data._borrower,
    //         data._lender,
    //         data._loanAmount,
    //         data._interestRate,
    //         data._loanDuration,
    //         data._erc20Token,
    //         data._nonce
    //     );

    //     _icryptoVault.depositNftToEscrowAndERC20ToBorrower( 
    //         data._contract,
    //         data._tokenId,
    //         data._erc20Token,
    //         data._lender,
    //         data._borrower,
    //         data._loanAmount
    //     );

    //     receiptIdBorrower = _ireceipts.generateBorrowerReceipt(data._contract,tokenId,borrower);
    //     receiptIdLender = _ireceipts.generateLenderReceipt(data._contract,tokenId,lender);

    //     return(receiptIdBorrower, receiptIdLender);
    //     // Transfer the ERC20 amount from the borrower to the vault
    //     // IERC20 erc20Token = IERC20(loan.currencyERC20);

    //     // erc20Token.safeTransferFrom(
    //     //     loan.lender,
    //     //     loan.borrower,
    //     //     loan.loanAmount
    //     // );
    //     //  uint256 receiptLender =_ireceipts.generateLenderReceipt(loan.lender);
    // }

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
    
    
    function acceptLoanOfferNative(
        // bytes calldata acceptOfferSignature,
        SignatureUtils.LoanOfferNative calldata loanOffer
    ) external payable nonReentrant returns(uint256 receiptIdBorrower, uint256 receiptIdLender ) {

        require(vault != address(0), "Vault address not set");

        require(msg.value != 0,"Loan Amount Invalid");

        require(_iwhiteListCollection.isWhiteList(loanOffer.nftContractAddress), "Collection is not White Listed");

        require(loanManager != address(0), "Loan manager address not set");

        require(receiptContract != address(0), "Receipt contract address not set");

        require(msg.sender == loanOffer.borrower || msg.sender == loanOffer.lender ,"Unauthorized sender");

        require(!_nonceUsedForUser[loanOffer.lender][loanOffer.nonce] && !_nonceUsedForUser[loanOffer.borrower][loanOffer.nonce], "Offer nonce invalid");
        _nonceUsedForUser[loanOffer.lender][loanOffer.nonce] = true;
        _nonceUsedForUser[loanOffer.borrower][loanOffer.nonce] = true;

     
        // if(loanOffer.borrower == msg.sender){
        //     require(
        //         SignatureUtils.validateSignatureApprovalOffer(
        //             acceptOfferSignature,
        //             loanOffer
        //         ),
        //         "Invalid lender signature"
        //     );
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

        (ILoanManager.Loan memory loan,uint256 _loanId) = _iloanManager.getLoan(
            loanOffer.nftContractAddress,
            loanOffer.tokenId,
            loanOffer.borrower,
            loanOffer.nonce
        );

        require(!loan.isPaid, "Loan offer is closed");
        // require(!loan.isPaid || !loan.isDefault , "Changed the nonce. Already created against this NFT");


        require(!loan.isApproved, "Loan offer is already approved");

        _iloanManager.createLoan(
            loanOffer.nftContractAddress,
            loanOffer.tokenId,
            loanOffer.borrower,
            loanOffer.lender,
            msg.value,
            loanOffer.interestRate,
            loanOffer.loanDuration,
            address(0),
            loanOffer.nonce
        );

        _iloanManager.updateIsApproved(_loanId, true);

        _icryptoVault.depositNftToEscrowAndnativeToBorrower( 
            loanOffer.nftContractAddress,
            loanOffer.tokenId,
            loanOffer.borrower);

        // (bool sentBorrower, ) = (loanOffer.borrower).call{value: msg.value}("");
        // require(sentBorrower, "Transfer to lender failed");
            
        receiptIdBorrower = _ireceipts.generateBorrowerReceipt(loanOffer.nftContractAddress,loanOffer.tokenId,loanOffer.borrower);
        receiptIdLender = _ireceipts.generateLenderReceipt(loanOffer.nftContractAddress,loanOffer.tokenId,loanOffer.lender);

        return(receiptIdBorrower, receiptIdLender);
    }

    function acceptLoanOffer(
        // bytes calldata acceptOfferSignature,
        SignatureUtils.LoanOffer calldata loanOffer
    ) external nonReentrant returns(uint256 receiptIdBorrower, uint256 receiptIdLender , ILoanManager.Loan memory) {

        require(vault != address(0), "Vault address not set");

        require(_iwhiteListCollection.isWhiteList(loanOffer.nftContractAddress), "Collection is not White Listed");

        require(loanManager != address(0), "Loan manager address not set");

        require(receiptContract != address(0), "Receipt contract address not set");

        require(loanOffer.loanDuration > block.timestamp,"Loan duration must b greater than current timestamp");

        require(msg.sender == loanOffer.borrower || msg.sender == loanOffer.lender ,"Unauthorized sender");

        require(!_nonceUsedForUser[loanOffer.lender][loanOffer.nonce] && !_nonceUsedForUser[loanOffer.borrower][loanOffer.nonce], "Offer nonce invalid");
        _nonceUsedForUser[loanOffer.lender][loanOffer.nonce] = true;
        _nonceUsedForUser[loanOffer.borrower][loanOffer.nonce] = true;

     
        // if(loanOffer.borrower == msg.sender){
        //     require(
        //         SignatureUtils.validateSignatureApprovalOffer(
        //             acceptOfferSignature,
        //             loanOffer
        //         ),
        //         "Invalid lender signature"
        //     );
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

        (ILoanManager.Loan memory loan,uint256 _loanId) = _iloanManager.getLoan(
            loanOffer.nftContractAddress,
            loanOffer.tokenId,
            loanOffer.borrower,
            loanOffer.nonce
        );

        require(!loan.isPaid, "Loan offer is closed");
        // require(!loan.isPaid || !loan.isDefault , "Changed the nonce. Already created against this NFT");


        require(!loan.isApproved, "Loan offer is already approved");

        // loan.isApproved =  true;

        // _iloanManager.updateIsApproved(_loanId, true);

        _iloanManager.createLoan(
            loanOffer.nftContractAddress,
            loanOffer.tokenId,
            loanOffer.borrower,
            loanOffer.lender,
            loanOffer.loanAmount,
            loanOffer.interestRate,
            loanOffer.loanDuration,
            loanOffer.erc20TokenAddress,
            loanOffer.nonce
        );

         _iloanManager.updateIsApproved(_loanId, true);

        _icryptoVault.depositNftToEscrowAndERC20ToBorrower( 
            loanOffer.nftContractAddress,
            loanOffer.tokenId,
            loanOffer.erc20TokenAddress,
            loanOffer.lender,
            loanOffer.borrower,
            loanOffer.loanAmount
        );
        receiptIdBorrower = _ireceipts.generateBorrowerReceipt(loanOffer.nftContractAddress,loanOffer.tokenId,loanOffer.borrower);
        receiptIdLender = _ireceipts.generateLenderReceipt(loanOffer.nftContractAddress,loanOffer.tokenId,loanOffer.lender);

        return(receiptIdBorrower, receiptIdLender,loan);
    }


//*****************************************************************************************************************************//
//*****************************************************************************************************************************//

    function payBackLoan(uint256 _loanId, address erc20Token) external nonReentrant returns (bool){
        ILoanManager.Loan memory loan = _iloanManager.getLoanById(_loanId);
        require(loan.currencyERC20 == erc20Token, "Currency Invalid");
        uint256 remainingAmount = _iloanManager.getPayoffAmount(_loanId);

        (uint256 _borrowerReceiptId,) = _ireceipts.getBorrowerReceiptId(loan.nftContract, loan.tokenId);
        (uint256 _lenderReceiptId,) = _ireceipts.getLenderReceiptId(loan.nftContract, loan.tokenId);
        _sanityCheck(loan, _lenderReceiptId, _borrowerReceiptId);
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

    function payBackLoan(uint256 _loanId) external payable nonReentrant returns(bool){
        ILoanManager.Loan memory loan = _iloanManager.getLoanById(_loanId);
        require(loan.currencyERC20==address(0), "Currency Invalid");
        (uint256 _borrowerReceiptId,) = _ireceipts.getBorrowerReceiptId(loan.nftContract, loan.tokenId);
        (uint256 _lenderReceiptId,) = _ireceipts.getLenderReceiptId(loan.nftContract, loan.tokenId);
        _sanityCheck(loan, _lenderReceiptId, _borrowerReceiptId);

        uint256 remainingAmount = _iloanManager.getPayoffAmount(_loanId);
        require(
            msg.value >= remainingAmount,
            "Repayment amount must be greater than or equal to amount with interest"
        );

        _iloanManager.updateIsPaid(_loanId, true);

        // Handle refund if msg.value exceeds the required repayment amount
        if (msg.value > remainingAmount) {
            (bool sentLender, ) = (loan.lender).call{value: remainingAmount}("");
            require(sentLender, "Transfer to lender failed");
            uint256 refundAmount = msg.value - remainingAmount;
            (bool sentRefund, ) = msg.sender.call{value: refundAmount}("");
            require(sentRefund, "Refund failed");
        }
        else {
            (bool sentLender, ) = (loan.lender).call{value: msg.value}("");
            require(sentLender, "Transfer to lender failed");
        }

        _icryptoVault.withdrawNftFromEscrow(loan.nftContract,loan.tokenId ,loan.borrower);

        _ireceipts.burnReceipt(_lenderReceiptId);
        _ireceipts.burnReceipt(_borrowerReceiptId);

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

    function _sanityCheck(ILoanManager.Loan memory loan, uint256 _lenderReceiptId,uint256 _borrowerReceiptId) internal view {
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


}



