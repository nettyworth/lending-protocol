// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IwhiteListCollection.sol";
import "./interfaces/ICryptoVault.sol";
import "./interfaces/ILoanManager.sol";
import "./library/SignatureUtils.sol";
import "./interfaces/IReceipts.sol";

contract NettyWorthProxy is ReentrancyGuard, Initializable,Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    address public vault;
    address public loanManager;
    address public lenderReceiptContract; 
    address public borrowerReceiptContract;
    address public whiteListContract;
    uint256 public adminFeeInBasisPoints = 400; // initial admin fee 4%.
    uint256 private proposeAdminFeeInBasisPoints;

    uint256 public constant BPS = 10000; // 10000 in basis points = 100%.
    address public adminWallet;
    address private _updateAdminWallet;

    ICryptoVault _icryptoVault;
    ILoanManager _iloanManager;
    ReceiptInterface _ireceiptLender;
    ReceiptInterface _ireceiptBorrower;
    IwhiteListCollection _iwhiteListCollection;

    event LoanRepaid(
        uint256 indexed loanId,
        address indexed nftContract,
        uint256[] tokenIds,
        address borrower,
        address lender,
        uint256 repayment,
        address erc20Address,
        bool isPaid
    );

    event LoanForClosed(
        uint256 indexed loanId,
        address indexed nftContract,
        uint256[] tokenIds,
        address borrower,
        address lender,
        bool isDefault
    );

    event UpdatedAdminFee(uint256 oldAdminFee, uint256 newAdminFee);
    event UpdatedAdminWallet(address oldAdminWallet, address newAdminWallet);

    constructor() Ownable(msg.sender){}

    function proposeAdminWallet(address _adminWallet) public onlyOwner {
        require(_adminWallet != address(0), "Invalid Address");
        _updateAdminWallet = _adminWallet;
    } 
    function setAdminWallet() public onlyOwner {
        adminWallet = _updateAdminWallet;
        _updateAdminWallet =  address(0);
        emit UpdatedAdminWallet(msg.sender,adminWallet);
    }

    function proposeUpdateAdminFee(uint256 _newAdminFee) public onlyOwner {
        require(
            _newAdminFee <= 500, // 500 in BPS = 5%
            "By definition, basis points cannot exceed 500(5%)."
        );
        proposeAdminFeeInBasisPoints = _newAdminFee;
    }

    function updateAdminFee() public onlyOwner {
        uint256 oldAdminFee = adminFeeInBasisPoints;
        adminFeeInBasisPoints = proposeAdminFeeInBasisPoints;
        proposeAdminFeeInBasisPoints = 0;
        emit UpdatedAdminFee(oldAdminFee,adminFeeInBasisPoints);
    }

    function initialize(
        address _vault,
        address _loanManager,
        address _lenderReceiptContract,
        address _borrowerReceiptContract,
        address _iwhiteListContract,
        address _adminWallet
    ) external initializer {
        setVault(_vault);
        setLoanManager(_loanManager);
        setReceiptContractLender(_lenderReceiptContract); 
        setReceiptContractBorrower(_borrowerReceiptContract);
        setWhiteListContract(_iwhiteListContract);
        proposeAdminWallet(_adminWallet);
        setAdminWallet();
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

    function setReceiptContractLender(address _lenderReceiptContract) public onlyOwner {
        require(_lenderReceiptContract != address(0), "Invalid address");
        lenderReceiptContract = _lenderReceiptContract;
        _ireceiptLender = ReceiptInterface(lenderReceiptContract);
    }

    function setReceiptContractBorrower(address _borrowerReceiptContract) public onlyOwner {
        require(_borrowerReceiptContract != address(0), "Invalid address");
        borrowerReceiptContract = _borrowerReceiptContract;
        _ireceiptBorrower = ReceiptInterface(borrowerReceiptContract);
    }

    function acceptLoanRequest(
        bytes calldata acceptRequestSignature,
        SignatureUtils.LoanRequest calldata loanRequest
    )
        external
        nonReentrant
        returns (uint256 receiptIdBorrower, uint256 receiptIdLender)
    {
        _sanityCheckAcceptOffer(
            loanRequest.nftContractAddress,
            loanRequest.erc20TokenAddress
            // loanRequest.loanDuration
            );
        require(
            SignatureUtils._validateRequestLoanSignature(
                acceptRequestSignature,
                loanRequest
            ),
            "Invalid borrower signature"
        );
        require(msg.sender != loanRequest.borrower, "Unauthorized sender");
        ILoanManager.LoanData memory loandata = ILoanManager.LoanData(
            loanRequest.nftContractAddress,
            loanRequest.tokenIds,
            loanRequest.borrower,
            msg.sender,
            loanRequest.loanAmount,
            loanRequest.aprBasisPoints,
            loanRequest.loanDuration + block.timestamp,
            loanRequest.erc20TokenAddress);
        (receiptIdBorrower, receiptIdLender) = _acceptOffer(
            loandata,
            loanRequest.nonce
        );

        return (receiptIdBorrower, receiptIdLender);
    }

    function acceptLoanOffer(
        bytes calldata acceptOfferSignature,
        SignatureUtils.LoanOffer calldata loanOffer
    )
        external
        nonReentrant
        returns (uint256 receiptIdBorrower, uint256 receiptIdLender)
    {
        require(msg.sender == loanOffer.borrower, "Unauthorized sender");
        _sanityCheckAcceptOffer(
            loanOffer.nftContractAddress,
            loanOffer.erc20TokenAddress
            // loanOffer.loanDuration
            );
        require(
            SignatureUtils._validateSignatureApprovalOffer(
                acceptOfferSignature,
                loanOffer
            ),
            "Invalid lender signature"
        );
        ILoanManager.LoanData memory loandata = ILoanManager.LoanData(
            loanOffer.nftContractAddress,
            loanOffer.tokenIds,
            loanOffer.borrower,
            loanOffer.lender,
            loanOffer.loanAmount,
            loanOffer.aprBasisPoints,
            loanOffer.loanDuration + block.timestamp,
            loanOffer.erc20TokenAddress);
        (receiptIdBorrower, receiptIdLender) = _acceptOffer(
            loandata,
            loanOffer.nonce
        );

        return (receiptIdBorrower, receiptIdLender);
    }

    function acceptLoanCollectionOffer(
        bytes calldata acceptOfferSignature,
        SignatureUtils.LoanCollectionOffer calldata loanCollectionOffer,
        uint256[] calldata tokenIds
    )
        external
        nonReentrant
        returns (uint256 receiptIdBorrower, uint256 receiptIdLender)
    {
        _sanityCheckAcceptOffer(
            loanCollectionOffer.collectionAddress,
            loanCollectionOffer.erc20TokenAddress
            // loanCollectionOffer.loanDuration
        );
        require(
            SignatureUtils._validateLoanCollectionOfferSignature(
                acceptOfferSignature,
                loanCollectionOffer
            ),
            "Invalid lender signature"
        );
        ILoanManager.LoanData memory loandata = ILoanManager.LoanData(loanCollectionOffer.collectionAddress,
            tokenIds,
            msg.sender,
            loanCollectionOffer.lender,
            loanCollectionOffer.loanAmount,
            loanCollectionOffer.aprBasisPoints,
            loanCollectionOffer.loanDuration + block.timestamp,
            loanCollectionOffer.erc20TokenAddress);
        (receiptIdBorrower, receiptIdLender) = _acceptOffer(
            loandata,
            loanCollectionOffer.nonce
        );

        return (receiptIdBorrower, receiptIdLender);
    }

    function _acceptOffer(
       ILoanManager.LoanData memory loandata,
        uint256 nonce
    ) internal returns (uint256 _receiptIdBorrower, uint256 _receiptIdLender) {
        (ILoanManager.Loan memory loan, uint256 _loanId) = _iloanManager.getLoan(
            loandata.nftContract,
            loandata.tokenIds,
            loandata.borrower,
            nonce
        );
        require(!loan.isPaid, "Loan offer is closed");
        require(!loan.isApproved, "Loan offer is already approved");
        _receiptIdBorrower = _ireceiptBorrower.generateReceipt(
            _loanId,
            loandata.borrower
        );
        _receiptIdLender = _ireceiptLender.generateReceipt(
            _loanId,
            loandata.lender
        );

        _iloanManager.setLoanId(_receiptIdLender,_loanId);
        _iloanManager.createLoan(
          loandata,
          _receiptIdLender,
          _receiptIdBorrower,
          nonce
        );
        _iloanManager.updateIsApproved(_loanId, true);
        _deposit(
            loandata.nftContract,
            _loanId,
            loandata.tokenIds,
            loandata.currencyERC20,
            loandata.lender,
            loandata.borrower,
            loandata.loanAmount
        );
    return (_receiptIdBorrower, _receiptIdLender);
    }

    function _deposit(
        address collectionAddress,
        uint256 loanid,
        uint256[] memory tokenIds,
        address erc20TokenAddress,
        address lender,
        address borrower,
        uint256 loanAmount
    ) internal {
        _icryptoVault.depositNftToEscrowAndERC20ToBorrower(
            collectionAddress,
            loanid,
            tokenIds,
            erc20TokenAddress,
            lender,
            borrower,
            loanAmount
        );
    }

    function payBackLoan(
        uint256 _loanId,
        address erc20Token
    ) external nonReentrant returns (bool) {
        ILoanManager.Loan memory loan = _iloanManager.getLoanById(_loanId);
        require(loan.currencyERC20 == erc20Token, "Currency Invalid");
        (uint256 rePaymentAmount, uint256 interestAmount) = _iloanManager.getPayoffAmount(_loanId);
        uint256 computeAdminFee = _computeAdminFee(interestAmount, adminFeeInBasisPoints);
        (address currentBorrower, address currentLender) = _sanityCheckPayBack(loan);
        _icryptoVault.withdrawNftFromEscrowAndERC20ToLender(
            loan.nftContract,
            _loanId,
            loan.tokenIds,
            currentBorrower,
            currentLender,
            rePaymentAmount,
            computeAdminFee,
            loan.currencyERC20,
            adminWallet
        );
        _ireceiptLender.burnReceipt(loan.lenderReceiptId);
        _ireceiptBorrower.burnReceipt(loan.borrowerReceiptId);

        _iloanManager.updateIsPaid(_loanId, true);

        emit LoanRepaid(
            _loanId,
            loan.nftContract,
            loan.tokenIds,
            currentBorrower,
            currentLender,
            rePaymentAmount,
            loan.currencyERC20,
            loan.isPaid
        );

    return true;
    }

    function forCloseLoan(uint256 _loanId) external nonReentrant returns (bool){
        ILoanManager.Loan memory loan = _iloanManager.getLoanById(_loanId);
        require(
            block.timestamp > loan.loanDuration,
            "User is not default yet::"
        );
        require(!loan.isPaid, "Loan Paid");
        require(!loan.isDefault, "Already Claimed");
        uint256 _borrowerReceiptId = loan.borrowerReceiptId;
        uint256 _lenderReceiptId = loan.lenderReceiptId;
        require(
            _ireceiptLender.tokenExist(_lenderReceiptId),
            "Receipt does not exist"
        );
        require(
            _ireceiptBorrower.tokenExist(_borrowerReceiptId),
            "Receipt does not exist"
        );
        address lender = _ireceiptLender.ownerOf(_lenderReceiptId);
        address borrower = _ireceiptBorrower.ownerOf(_borrowerReceiptId);
        require(
             lender == msg.sender,
            "You are not the lender"
        );

        _iloanManager.updateIsDefault(_loanId, true);
        _icryptoVault.withdrawNftFromEscrow(
            loan.nftContract,
            _loanId,
            loan.tokenIds,
            lender
        );

        _ireceiptLender.burnReceipt(_lenderReceiptId);
        _ireceiptBorrower.burnReceipt(_borrowerReceiptId);

        emit LoanForClosed(
            _loanId,
            loan.nftContract,
            loan.tokenIds,
            borrower,
            loan.lender,
            loan.isDefault
        );

    return true;
    }

    function getLenderReceiptId(uint256 loanId) external view returns(uint256 holderReceiptId, address holderAddress){
        require(loanId != 0, "200:ZERO_LoanID");
        (holderReceiptId, holderAddress) = _ireceiptLender.getReceiptId(loanId);
        return (holderReceiptId, holderAddress);
    }

    function getBorrowerReceiptId(uint256 loanId) external view returns(uint256 holderReceiptId, address holderAddress){
        require(loanId != 0, "200:ZERO_LoanID");
        (holderReceiptId, holderAddress) = _ireceiptBorrower.getReceiptId(loanId);
        return (holderReceiptId, holderAddress);
    } 

    //you can pass either lender receipt ID or Borrower receiptID both are same for each loan
    function getLoanId(uint256 _LoanReceiptId) external view returns(uint256 loanId){
        require(_ireceiptLender.tokenExist(_LoanReceiptId), "Receipt does not exist");
        loanId = _iloanManager.getLoanId(_LoanReceiptId);
        return loanId;
    }

    function _computeAdminFee(
        uint256 _interest,
        uint256 _adminFee
    ) internal pure returns (uint256) {
        return (_interest * (_adminFee)) / BPS;
    }

    function _sanityCheckPayBack(ILoanManager.Loan memory loan) internal view returns (address _borrower, address _lender){
          require(
            block.timestamp <= loan.loanDuration,
            "Loan repayment period has expired"
        );
        require(loan.isApproved, "Loan offer not approved");
        require(!loan.isDefault, "borrower is defaulter now");
        require(!loan.isPaid, "Loan is Paid");
        require(loan.lender != address(0), "Loan is not assigned to a lender");
        require(
            _ireceiptLender.tokenExist(loan.lenderReceiptId),
            "Receipt does not exist"
        );
        require(      
            _ireceiptBorrower.tokenExist(loan.borrowerReceiptId),
            "Receipt does not exist"
        );
        address lender = _ireceiptLender.ownerOf(loan.lenderReceiptId);
        address borrower = _ireceiptBorrower.ownerOf(loan.borrowerReceiptId);
        require(borrower == msg.sender, "caller is not borrower");        
    return (borrower,lender);
    }

    function _sanityCheckAcceptOffer(
        address nftContractAddress,
        address erc20Address
        // uint256 loanDuration
    ) internal view {
        require(vault != address(0), "Vault address not set");
        require(
            _iwhiteListCollection.isWhiteListCollection(nftContractAddress),
            "Collection is not White Listed"
        );
        require(
            _iwhiteListCollection.isWhiteListErc20Token(erc20Address),
            "Token is not White Listed"
        );
        require(loanManager != address(0), "Loan manager address not set");
        require(
            lenderReceiptContract != address(0),
            "Receipt Lender contract address not set"
        );
        require(
            borrowerReceiptContract != address(0),
            "Receipt Borrower contract address not set"
        );
        // require(
        //     loanDuration > block.timestamp,
        //     "Loan duration must b greater than current timestamp"
        // );
    }
    
    function renounceOwnership() public view override onlyOwner {
    }
}
