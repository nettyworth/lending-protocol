// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILoanManager {

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
    function createLoan(
        LoanData calldata loanData,
        uint256 lenderReceiptId,
        uint256 borrowerReceiptId,
        uint256 _nonce
    ) external;

    function updateLoan(Loan memory loan, uint256 loanId) external returns(bool);

    function getLoan(
        address _contract,
        uint256[] calldata _tokenIds,
        address _borrower,
        uint256 _nonce
    ) external view returns (Loan memory loan, uint256 loanId);

    function updateIsPaid(uint256 loanId, bool state) external;

    function updateIsDefault(uint256 loanId, bool state) external;

    function updateIsApproved(uint256 loanId, bool state) external;
    
    function setLoanId(uint256 loanReceiptID, uint256 loanId) external;

    function getPayoffAmount(uint256 loanId) external view returns(uint256, uint256);
    
    function getLoanById(uint256 loanId) external view returns (Loan memory loan); 

    function getLoanId(uint256 loanReceiptID) external view returns(uint256 loanID);

    // function updateBorrower(uint256 loanId, address newBorrower) external;

    // function updateLender(uint256 loanId, address newLender) external;
    
    // function getCurrentBorrower(uint256 loanId) external view returns (address currentBorrower);

    // function getCurrentLender(uint256 loanId) external view returns (address currentLender);
}
