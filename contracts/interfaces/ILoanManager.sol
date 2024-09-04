// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ILoanManager {

    struct LoanData {
        address _contract;
        uint256 _tokenId;
        address _borrower;
        address _lender;
        uint256 _loanAmount;
        uint256 _interestRate;
        uint256 _loanDuration;
        address _erc20Token;
        uint256 _nonce;
    }
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

    function approveLoanOffer(
        address _nftContract,
        uint256 _tokenId,
        address _borrower
    ) external;

    function getLoan(
        address _contract,
        uint256 _tokenId,
        address _borrower,
        uint256 _nonce
    ) external view returns (Loan memory);

    function getLoanId(
        address _contract,
        uint256 _tokenId,
        address _borrower
    ) external pure returns (uint256);

    // function createLoan(
    //    LoanData memory 
    // ) external;

    function createLoan(
        address _contract,
        uint256 _tokenId,
        address _borrower,
        address _lender,
        uint256 _loanAmount,
        uint256 _interestRate,
        uint256 _loanDuration,
        address _erc20Token,
        uint256 _nonce
    ) external;

    function getPayoffAmount(uint256 _loanId) external view returns(uint256);

    function deleteLoan(address nftColletralAddress, uint256 _tokenId ,address _borrower) external;

    function makePayment(uint256 _loanId) external payable;

    function redeemLoan(uint256 _loanId) external;

    // function getLoans(address _contract) external view returns (Loan[] memory);
}
