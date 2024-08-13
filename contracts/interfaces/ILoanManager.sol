// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILoanManager {
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

    function approveLoanOffer(address _nftContract,
     uint256 _tokenId, address _borrower) external;

    
    function getLoan(address _contract, uint256 _tokenId, address _borrower) external view returns (Loan memory);

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
    

    function makePayment(address _lender, uint256 _loanIndex) external payable;

    function redeemLoan(address _borrower, uint256 _loanIndex) external;

    function getLoans(address _contract) external view returns (Loan[] memory);
}

