// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILoanManager {

    struct Loan {
        address nftContract;
        uint256 tokenId;
        address borrower;
        address lender;
        uint256 loanAmount;
        uint256 aprBasisPoints;
        uint256 loanDuration;
        address currencyERC20;
        uint256 loanInitialTime;
        bool isPaid;
        bool isDefault;
        bool isApproved;
    }

    function createLoan(
        address _contract,
        uint256 _tokenId,
        address _borrower,
        address _lender,
        uint256 _loanAmount,
        uint256 __aprBasisPoints,
        uint256 _loanDuration,
        address _erc20Token,
        uint256 _nonce
    ) external;

    function updateLoan(Loan memory loan, uint256 loanId) external returns(bool);

    function getLoan(
        address _contract,
        uint256 _tokenId,
        address _borrower,
        uint256 _nonce
    ) external view returns (Loan memory loan, uint256 loanId);

    function updateIsPaid(uint256 loanId, bool state) external;

    function updateIsDefault(uint256 loanId, bool state) external;

    function updateIsApproved(uint256 loanId, bool state) external;

    function getPayoffAmount(uint256 loanId) external view returns(uint256, uint256);
    
    function getLoanById(uint256 loanId) external view returns (Loan memory loan); 

}
