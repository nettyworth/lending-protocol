// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract LoanCalculator {
    using SafeMath for uint256;

    uint256 private constant SECONDS_PER_DAY = 86400;
    uint256 private constant DAYS_PER_YEAR = 365;
    uint256 private constant BASIS_POINTS = 10000;

    function computeLoanRepayment(
        uint256 principal,
        uint256 aprBasisPoints,
        uint256 loanDurationDays
    ) public pure returns (uint256 repaymentAmount, uint256 interestAmount) {
        require(principal > 0, "Principal must be greater than zero");
        require(aprBasisPoints > 0 && aprBasisPoints <= BASIS_POINTS, "Invalid APR");
        require(loanDurationDays > 0, "Loan duration must be greater than zero");

        // Use SafeMath for all calculations to prevent overflows
        uint256 interestRatePerSecond = aprBasisPoints.mul(SECONDS_PER_DAY).div(DAYS_PER_YEAR.mul(BASIS_POINTS));
        uint256 loanDurationSeconds = loanDurationDays.mul(SECONDS_PER_DAY);

        interestAmount = principal.mul(interestRatePerSecond).mul(loanDurationSeconds).div(SECONDS_PER_DAY);
        repaymentAmount = principal.add(interestAmount);

        return (repaymentAmount, interestAmount);
    }

    function getEffectiveInterestRate(
        uint256 principal,
        uint256 repaymentAmount,
        uint256 loanDurationDays
    ) public pure returns (uint256) {
        require(principal > 0, "Principal must be greater than zero");
        require(repaymentAmount > principal, "Repayment amount must be greater than principal");
        require(loanDurationDays > 0, "Loan duration must be greater than zero");

        uint256 interestAmount = repaymentAmount.sub(principal);
        uint256 effectiveRate = interestAmount.mul(DAYS_PER_YEAR).mul(BASIS_POINTS).div(principal.mul(loanDurationDays));

        return effectiveRate;
    }

    function isLeapYear(uint256 year) public pure returns (bool) {
        return (year % 4 == 0) && (year % 100 != 0 || year % 400 == 0);
    }

    function getDaysInYear(uint256 year) public pure returns (uint256) {
        return isLeapYear(year) ? 366 : 365;
    }

    function convertTimestampToDays(uint256 timestamp) public pure returns (uint256) {
        return timestamp.div(SECONDS_PER_DAY);
    }

    function calculateAndStoreRepayment(
        uint256 principal,
        uint256 aprBasisPoints,
        uint256 loanDurationDays
    ) public pure returns (uint256) {
        (uint256 repaymentAmount, ) = computeLoanRepayment(principal, aprBasisPoints, loanDurationDays);
        return repaymentAmount;
    }
}



contract LoanManager is LoanCalculator {
    // ... existing code ...

    function createLoan(
        // ... other parameters ...
        uint256 _aprBasisPoints,
        uint256 _loanDuration
    ) external {
        // ... other logic ...
        uint256 loanDurationDays = convertTimestampToDays(_loanDuration);
        uint256 repaymentAmount = calculateAndStoreRepayment(_loanAmount, _aprBasisPoints, loanDurationDays);
        loans[_loanId] = Loan({
            // ... other fields ...
            aprBasisPoints: _aprBasisPoints,
            loanDuration: _loanDuration,
            rePayment: repaymentAmount
        });
    }

    function getPayoffAmount(uint256 loanId) public view returns(uint256) {
        Loan storage loan = loans[loanId];
        require(!loan.isPaid, "Loan is Paid");
        return loan.rePayment;
    }
}