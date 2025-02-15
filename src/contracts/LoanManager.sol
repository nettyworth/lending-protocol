// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICryptoVault.sol";
import "./interfaces/IReceipts.sol";

contract LoanManager is Ownable {
    struct Loan {
        address nftContract;
        uint256[] tokenIds;
        address borrower;
        address lender;
        uint256 loanAmount;
        uint256 aprBasisPoints;
        uint256 loanDuration;
        address currencyERC20;
        uint256 loanInitialTime;
        uint256 lenderReceiptId;
        uint256 borrowerReceiptId;
        bool isPaid;
        bool isDefault;
        bool isApproved;
    }

    struct LoanData {
        address nftContract;
        uint256[] tokenIds;
        address borrower;
        address lender;
        uint256 loanAmount;
        uint256 aprBasisPoints;
        uint256 loanDuration;
        address currencyERC20;
    }
    event LoanCreated(
        uint256 indexed loanId,
        LoanData,
        uint256 loanInitialTime,
        bool isPaid,
        bool isClosed,
        bool isApproved
    );
    using SafeERC20 for IERC20;
    uint256 public NFT_MAX_LIMIT = 10;
    uint256 private _propose_NFT_LIMIT;
    uint256 constant SECONDS_IN_YEAR = 31536000;
    uint256 public constant BPS = 10000; //100%
    uint256 public constant MAX_APR = 50000; // 500%

    // Loan ID -> Loan
    mapping(uint256 => Loan) private _loans;
    mapping(address => mapping(uint256 => bool)) private _nonceUsedForUser;
    mapping(uint256 => uint256) private _loanId;
    address public _proxy;
    address private _proposeproxy;

    constructor() Ownable(msg.sender) {}

    function createLoan(
        LoanData calldata loanData,
        uint256 lenderReceiptId,
        uint256 borrowerReceiptId,
        uint256 nonce
    ) external onlyProxyManager returns (uint256 loanId) {
        _validateLoanCreation(loanData, nonce);

        (, uint256 loanID) = getLoan(
            loanData.nftContract,
            loanData.tokenIds,
            loanData.borrower,
            nonce
        );
        // Create a new loan
        require(
            _loans[loanID].nftContract == address(0),
            "Loan already created"
        );

        _loans[loanID] = Loan({
            nftContract: loanData.nftContract,
            tokenIds: loanData.tokenIds,
            borrower: loanData.borrower,
            lender: loanData.lender,
            loanAmount: loanData.loanAmount,
            aprBasisPoints: loanData.aprBasisPoints,
            loanDuration: loanData.loanDuration,
            currencyERC20: loanData.currencyERC20,
            loanInitialTime: block.timestamp,
            lenderReceiptId: lenderReceiptId,
            borrowerReceiptId: borrowerReceiptId,
            isPaid: false,
            isDefault: false,
            isApproved: false
        });
        emit LoanCreated(
            loanID,
            loanData,
            block.timestamp,
            false,
            false,
            false
        );
    return loanID;
    }

    function _validateLoanCreation(
        LoanData calldata loanData,
        uint256 _nonce
    ) internal {
        require(
            loanData.nftContract != address(0),
            "NFT contract address required"
        );
        require(
            loanData.tokenIds.length > 0 &&
                loanData.tokenIds.length <= NFT_MAX_LIMIT,
            "Token IDs required"
        );
        require(loanData.borrower != address(0), "Borrower address required");
        require(loanData.loanAmount > 0, "Loan amount must be greater than 0");
        require(
            loanData.aprBasisPoints >= 1 && loanData.aprBasisPoints <= MAX_APR,
            "Invalid APR"
        );
        require(
            loanData.loanDuration > 0,
            "Loan duration must be greater than 0"
        );
        require(loanData.lender != address(0), "Lender address required");
        require(
            !_nonceUsedForUser[loanData.lender][_nonce] &&
                !_nonceUsedForUser[loanData.borrower][_nonce],
            "Nonce invalid"
        );

        _nonceUsedForUser[loanData.lender][_nonce] = true;
        _nonceUsedForUser[loanData.borrower][_nonce] = true;
    }

    function updateIsPaid(
        uint256 loanId,
        bool state
    ) external onlyProxyManager {
        _loans[loanId].isPaid = state;
    }

    function updateIsDefault(
        uint256 loanId,
        bool state
    ) external onlyProxyManager {
        _loans[loanId].isDefault = state;
    }

    function updateIsApproved(
        uint256 loanId,
        bool state
    ) external onlyProxyManager {
        _loans[loanId].isApproved = state;
    }

    function setLoanId(uint256 loanReceiptID, uint256 loanId) external onlyProxyManager{
        _loanId[loanReceiptID] = loanId;
    }

    //you can pass either lender receipt ID or Borrower receiptID both are same for each loan
    function getLoanId(uint256 loanReceiptID) external view returns(uint256 loanID){
        loanID = _loanId[loanReceiptID];
        require(loanID != 0, "Loan not exist!");
        return loanID;
    }

    function getLoan(
        address _contract,
        uint256[] calldata _tokenIds,
        address _borrower,
        uint256 _nonce
    ) public view returns (Loan memory loan, uint256 loanId) {
        loanId = uint256(
            keccak256(abi.encode(_borrower, _contract, _tokenIds, _nonce))
        );
        loan = _loans[loanId];
        return (loan, loanId);
    }

    function getLoanById(
        uint256 loanId
    ) public view returns (Loan memory loan) {
        return _loans[loanId];
    }

    function getPayoffAmount(
        uint256 loanId
    ) public view returns (uint256, uint256) {
        Loan memory loan = _loans[loanId];
        require(!loan.isPaid, "Loan is Paid");
        require(loan.loanAmount > 0, "Principal must be greater than zero");
        require(
            loan.aprBasisPoints > 0 && loan.aprBasisPoints <= MAX_APR,
            "Invalid APR"
        );
        require(
            loan.loanDuration > 0,
            "Loan duration must be greater than zero"
        );

        uint256 loanDurationinSeconds = loan.loanDuration - loan.loanInitialTime;
        uint256 scalingFactor = 1e18;
        uint256 interestAmount = (loan.loanAmount *
            loan.aprBasisPoints *
            loanDurationinSeconds *
            scalingFactor) / (BPS * SECONDS_IN_YEAR);

        interestAmount = interestAmount / scalingFactor;
        uint256 repaymentAmount = loan.loanAmount + interestAmount;

        return (repaymentAmount, interestAmount);
    }

    function proposeNftMaxLimit(uint256 nftLimit) external {
        require(nftLimit != 0, "200:ZERO_Input");
        _propose_NFT_LIMIT = nftLimit;
    }

    function setNftMaxLimit() external {
        require(_propose_NFT_LIMIT != 0, "200:ZERO_Input");
        NFT_MAX_LIMIT = _propose_NFT_LIMIT;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyProxyManager() {
        require(
            _proxy == _msgSender(),
            "Ownable: caller is not the orchestrator"
        );
        _;
    }

    function proposeProxyManager(address newProxy) external onlyOwner {
        require(newProxy != address(0), "200:ZERO_ADDRESS");
        _proposeproxy = newProxy;
    }

    function setProxyManager() external onlyOwner {
        require(_proposeproxy != address(0), "200:ZERO_ADDRESS");
        _proxy = _proposeproxy;
        _proposeproxy = address(0);
    }

    function renounceOwnership() public view override onlyOwner {}
}
