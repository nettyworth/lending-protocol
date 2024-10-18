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
    address public receiptContract;
    address public whiteListContract;
    uint256 public adminFeeInBasisPoints = 400;
    uint256 private purposeAdminFeeInBasisPoints;

    uint256 public constant BPS = 10000;
    address public adminWallet;
    address private _updateAdminWallet;

    ICryptoVault _icryptoVault;
    ILoanManager _iloanManager;
    ReceiptInterface _ireceipts;
    IwhiteListCollection _iwhiteListCollection;

    event LoanRepaid(
        uint256 indexed loanId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address borrower,
        address lender,
        uint256 repayment,
        address erc20Address,
        bool isPaid
    );

    event LoanForClosed(
        uint256 indexed loanId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address borrower,
        address lender,
        bool isDefault
    );

    event UpdatedAdminFee(uint256 oldAdminFee, uint256 newAdminFee);
    event UpdatedAdminWallet(address oldAdminWallet, address newAdminWallet);

    constructor() Ownable(msg.sender){}

    function purposeAdminWallet(address _adminWallet) public onlyOwner {
        require(_adminWallet != address(0), "Invalid Address");
        _updateAdminWallet = _adminWallet;
    } 
    function setAdminWallet() public onlyOwner {
        adminWallet = _updateAdminWallet;
        _updateAdminWallet =  address(0);
        emit UpdatedAdminWallet(msg.sender,adminWallet);
    }

    function purposeUpdateAdminFee(uint256 _newAdminFee) public onlyOwner {
        require(
            _newAdminFee <= 1000, // 1000 in BPS = 10%
            "By definition, basis points cannot exceed 1000 "
        );
        purposeAdminFeeInBasisPoints = _newAdminFee;
    }
    function updateAdminFee() public onlyOwner {
        uint256 oldAdminFee = adminFeeInBasisPoints;
        adminFeeInBasisPoints = purposeAdminFeeInBasisPoints;
        purposeAdminFeeInBasisPoints = 0;
        emit UpdatedAdminFee(oldAdminFee,adminFeeInBasisPoints);
    }

    function initialize(
        address _vault,
        address _loanManager,
        address _receiptContract,
        address _iwhiteListContract,
        address _adminWallet
    ) external initializer {
        setVault(_vault);
        setLoanManager(_loanManager);
        setReceiptContract(_receiptContract);
        setWhiteListContract(_iwhiteListContract);
        purposeAdminWallet(_adminWallet);
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

    function setReceiptContract(address _receiptContract) public onlyOwner {
        require(_receiptContract != address(0), "Invalid address");
        receiptContract = _receiptContract;
        _ireceipts = ReceiptInterface(receiptContract);
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
            loanRequest.erc20TokenAddress,
            loanRequest.loanDuration);
        require(
            SignatureUtils._validateRequestLoanSignature(
                acceptRequestSignature,
                loanRequest
            ),
            "Invalid borrower signature"
        );
        (receiptIdBorrower, receiptIdLender) = _acceptOffer(
            loanRequest.nftContractAddress,
            loanRequest.tokenId,
            loanRequest.borrower,
            msg.sender, //lender,
            loanRequest.loanAmount,
            loanRequest.aprBasisPoints,
            loanRequest.loanDuration,
            loanRequest.erc20TokenAddress,
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
            loanOffer.erc20TokenAddress,
            loanOffer.loanDuration);
        require(
            SignatureUtils._validateSignatureApprovalOffer(
                acceptOfferSignature,
                loanOffer
            ),
            "Invalid lender signature"
        );
        (receiptIdBorrower, receiptIdLender) = _acceptOffer(
            loanOffer.nftContractAddress,
            loanOffer.tokenId,
            loanOffer.borrower,
            loanOffer.lender,
            loanOffer.loanAmount,
            loanOffer.aprBasisPoints,
            loanOffer.loanDuration,
            loanOffer.erc20TokenAddress,
            loanOffer.nonce
        );

        return (receiptIdBorrower, receiptIdLender);
    }

    function acceptLoanCollectionOffer(
        bytes calldata acceptOfferSignature,
        SignatureUtils.LoanCollectionOffer calldata loanCollectionOffer,
        uint256 tokenId
    )
        external
        nonReentrant
        returns (uint256 receiptIdBorrower, uint256 receiptIdLender)
    {
        IERC721 nft = IERC721(loanCollectionOffer.collectionAddress);
        require(
            nft.ownerOf(tokenId) == msg.sender,
            "Current caller is not the owner of NFT"
        );
        _sanityCheckAcceptOffer(
            loanCollectionOffer.collectionAddress,
            loanCollectionOffer.erc20TokenAddress,
            loanCollectionOffer.loanDuration
        );
        require(
            SignatureUtils._validateLoanCollectionOfferSignature(
                acceptOfferSignature,
                loanCollectionOffer
            ),
            "Invalid lender signature"
        );
        (receiptIdBorrower, receiptIdLender) = _acceptOffer(
            loanCollectionOffer.collectionAddress,
            tokenId,
            msg.sender,
            loanCollectionOffer.lender,
            loanCollectionOffer.loanAmount,
            loanCollectionOffer.aprBasisPoints,
            loanCollectionOffer.loanDuration,
            loanCollectionOffer.erc20TokenAddress,
            loanCollectionOffer.nonce
        );

        return (receiptIdBorrower, receiptIdLender);
    }

    function _acceptOffer(
        address collectionAddress,
        uint256 tokenId,
        address borrower,
        address lender,
        uint256 loanAmount,
        uint256 aprBasisPoints,
        uint256 loanDuration,
        address erc20TokenAddress,
        uint256 nonce
    ) internal returns (uint256 _receiptIdBorrower, uint256 _receiptIdLender) {
        (ILoanManager.Loan memory loan, uint256 _loanId) = _iloanManager
            .getLoan(collectionAddress, tokenId, borrower, nonce);
        require(!loan.isPaid, "Loan offer is closed");
        require(!loan.isApproved, "Loan offer is already approved");
        _iloanManager.createLoan(
            collectionAddress,
            tokenId,
            borrower,
            lender,
            loanAmount,
            aprBasisPoints,
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

        _receiptIdBorrower = _ireceipts.generateBorrowerReceipt(
            collectionAddress,
            tokenId,
            borrower
        );
        _receiptIdLender = _ireceipts.generateLenderReceipt(
            collectionAddress,
            tokenId,
            lender
        );

        return (_receiptIdBorrower, _receiptIdLender);
    }

    function _deposit(
        address collectionAddress,
        uint256 tokenId,
        address erc20TokenAddress,
        address lender,
        address borrower,
        uint256 loanAmount
    ) internal {
        _icryptoVault.depositNftToEscrowAndERC20ToBorrower(
            collectionAddress,
            tokenId,
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
        (uint256 rePaymentAmount, uint256 interestAmount) = _iloanManager
            .getPayoffAmount(_loanId);
        uint256 computeAdminFee = _computeAdminFee(
            interestAmount,
            adminFeeInBasisPoints
        );
        (uint256 _borrowerReceiptId, address unusedBorrowerAddress) = _ireceipts
            .getBorrowerReceiptId(loan.nftContract, loan.tokenId);
        (uint256 _lenderReceiptId, address unusedLenderAddress) = _ireceipts
            .getLenderReceiptId(loan.nftContract, loan.tokenId);
        _sanityCheckPayBack(loan, _lenderReceiptId, _borrowerReceiptId);

        _icryptoVault.withdrawNftFromEscrowAndERC20ToLender(
            loan.nftContract,
            loan.tokenId,
            loan.borrower,
            loan.lender,
            rePaymentAmount,
            computeAdminFee,
            loan.currencyERC20,
            adminWallet
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
            rePaymentAmount,
            loan.currencyERC20,
            loan.isPaid
        );

        return true;
    }

    function forCloseLoan(
        uint256 _loanId
    ) external nonReentrant returns (bool) {
        ILoanManager.Loan memory loan = _iloanManager.getLoanById(_loanId);
        require(
            block.timestamp > loan.loanDuration,
            "User is not default yet::"
        );
        require(!loan.isPaid, "Loan Paid");
        require(!loan.isDefault, "Already Claimed");
        (uint256 _borrowerReceiptId, address unusedBorrowerAddress) = _ireceipts
            .getBorrowerReceiptId(loan.nftContract, loan.tokenId);
        (uint256 _lenderReceiptId, address unusedlenderAddress) = _ireceipts
            .getLenderReceiptId(loan.nftContract, loan.tokenId);
        require(
            _ireceipts.tokenExist(_lenderReceiptId),
            "Receipt does not exist"
        );
        require(
            _ireceipts.tokenExist(_borrowerReceiptId),
            "Receipt does not exist"
        );
        address lender = _ireceipts.ownerOf(_lenderReceiptId);
        address borrower = _ireceipts.ownerOf(_borrowerReceiptId);
        require(loan.borrower == borrower, "Invalid borrower");
        require(
            loan.lender == lender && lender == msg.sender,
            "You are not the lender"
        );

        _iloanManager.updateIsDefault(_loanId, true);
        _icryptoVault.withdrawNftFromEscrow(
            loan.nftContract,
            loan.tokenId,
            loan.borrower,
            msg.sender
        );

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

    function _computeAdminFee(
        uint256 _interest,
        uint256 _adminFee
    ) internal pure returns (uint256) {
        return (_interest * (_adminFee)) / BPS;
    }

    function _sanityCheckPayBack(
        ILoanManager.Loan memory loan,
        uint256 _lenderReceiptId,
        uint256 _borrowerReceiptId
    ) internal view {
          require(
            block.timestamp < loan.loanDuration,
            "Loan repayment period has expired"
        );
        require(loan.isApproved, "Loan offer not approved");
        require(!loan.isDefault, "borrower is defaulter now");
        require(!loan.isPaid, "Loan is Paid");
        require(loan.lender != address(0), "Loan is not assigned to a lender");
        require(
            _ireceipts.tokenExist(_lenderReceiptId),
            "Receipt does not exist"
        );
        require(
            _ireceipts.tokenExist(_borrowerReceiptId),
            "Receipt does not exist"
        );
        address lender = _ireceipts.ownerOf(_lenderReceiptId);
        address borrower = _ireceipts.ownerOf(_borrowerReceiptId);
        require(
            loan.borrower == msg.sender && borrower == msg.sender,
            "caller is not borrower"
        );
        require(loan.lender == lender, "Invalid Lender");
    }

    function _sanityCheckAcceptOffer(
        address nftContractAddress,
        address erc20Address,
        uint256 loanDuration
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
            receiptContract != address(0),
            "Receipt contract address not set"
        );
        require(
            loanDuration > block.timestamp,
            "Loan duration must b greater than current timestamp"
        );
    }
    
    function renounceOwnership() public view override onlyOwner {
    }
}
