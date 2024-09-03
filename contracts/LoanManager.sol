// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract LoanManager is Ownable, ReentrancyGuard {
    struct Loan {
        address nftContract;
        uint256 tokenId;
        address borrower;
        address lender;
        uint256 loanAmount;
        uint256 interestRate;
        uint256 loanDuration;
        address currencyERC20;
        uint256 totalPaid;
        uint256 loanInitialTime;
        bool isClosed;
        bool isApproved;
    }

    event LoanCreated(
        uint256 indexed loanId,
        address nftContract,
        uint256 tokenId,
        address borrower,
        address lender,
        uint256 loanAmount,
        uint256 interestRate,
        uint256 loanDuration,
        address erc20Address,
        uint256 totalPaid,
        uint256 loanInitialTime,
        bool isClosed,
        bool isApproved
    );

    // Loan ID -> Loan
    mapping(uint256 => Loan) public loans;
    mapping(address => mapping(uint256 => Loan)) public loansIndexed;
    address public _proxy;

    constructor() Ownable(msg.sender) {}

    function createLoan(
        address _nftContract,
        uint256 _tokenId,
        address _borrower,
        address _lender,
        uint256 _loanAmount,
        uint256 _interestRate,
        uint256 _loanDuration,
        address _currencyERC20
    ) external onlyProxyManager {
        require(_nftContract != address(0), "NFT contract address is required");
        require(_tokenId > 0, "Token ID must be greater than 0");
        require(_borrower != address(0), "Borrower address is required");
        require(_loanAmount > 0, "Loan amount must be greater than 0");
        require(_interestRate >= 0, "Interest rate cannot be negative");
        require(_loanDuration > 0, "Loan duration must be greater than 0");
        require(
            _currencyERC20 != address(0),
            "Currency ERC-20 contract address is required"
        );
        require(_lender != address(0), "Lender address is required");
        uint256 _loanId = uint256(keccak256(abi.encodePacked(_borrower, _nftContract, _tokenId)));
        


        // Create a new loan
        require(
            loans[_loanId].nftContract == address(0),
            "Loan already created"
        );
    
        loans[_loanId] = Loan({
            nftContract: _nftContract,
            tokenId: _tokenId,
            borrower: _borrower,
            lender: _lender,
            loanAmount: _loanAmount,
            interestRate: _interestRate,
            loanDuration: _loanDuration,
            currencyERC20: _currencyERC20,
            totalPaid: 0,
            loanInitialTime: block.timestamp,
            isClosed: false,
            isApproved: false
        });
        loansIndexed[_borrower][_loanId] = loans[_loanId];
        emit LoanCreated(_loanId,
            _nftContract,
            _tokenId,
            _borrower,
            _lender,
            _loanAmount,
            _interestRate,
            _loanDuration,
            _currencyERC20,
            0,
            block.timestamp,
            false,
            false
        );
    }

    function getLoan(
        address _contract,
        uint256 _tokenId,
        address _borrower
    ) external view returns (Loan memory) {
        uint256 _loanId = uint256(
            keccak256(abi.encodePacked(_borrower, _contract, _tokenId))
        );
        return loans[_loanId];
    }

    
 // From borrower
    function makePayment(uint256 _loanIndex) external payable {
        Loan storage loan = loans[_loanIndex];
        require(!loan.isClosed, "Loan is closed");
        require(loan.lender != address(0), "Loan is not assigned to a lender");

        uint256 remainingAmount = loan.loanAmount +
            ((loan.loanAmount *
                loan.interestRate *
                (block.timestamp - loan.loanInitialTime)) /
                (100 * loan.loanDuration));

        require(
            msg.value <= remainingAmount,
            "Payment amount exceeds remaining amount"
        );

        loan.totalPaid += msg.value;
        if (loan.totalPaid >= loan.loanAmount) {
            loan.isClosed = true;
        }

        if (msg.value < remainingAmount) {
            payable(loan.borrower).transfer(msg.value);
        } else {
            payable(loan.borrower).transfer(remainingAmount);
            uint256 refundAmount = msg.value - remainingAmount;
            payable(msg.sender).transfer(refundAmount);
        }
    }

    function redeemLoan(uint256 _loanIndex) external nonReentrant {
        Loan memory loan = loans[_loanIndex];
        require(loan.borrower == msg.sender, "You are not the borrower");
        require(loan.isClosed, "Loan is not closed");

        uint256 remainingAmount = loan.loanAmount +
            (loan.loanAmount *
                loan.interestRate *
                (block.timestamp - loan.loanInitialTime)) /
            (100 * loan.loanDuration);
        require(loan.totalPaid >= remainingAmount, "Loan not fully paid");

        IERC721(loan.nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            loan.tokenId
        );
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

    function setProxyManager(address newProxy) external onlyOwner {
        require(newProxy != address(0), "200:ZERO_ADDRESS");
        _proxy = newProxy;
    }
}
