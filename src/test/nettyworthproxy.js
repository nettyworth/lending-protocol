// const { expect } = require("chai");
// const { ethers } = require("hardhat");

// describe("NettyWorthProxy", function () {
//   let owner, lender, borrower, adminWallet, otherUser;
//   let nettyWorthProxy, vault, loanManager, receiptContract, whiteListContract;

//   before(async function () {
//     [owner, lender, borrower, adminWallet, otherUser] =
//       await ethers.getSigners();

//     // Deploy mock contracts to be used in the tests
//     const MockVault = await ethers.getContractFactory("MockVault");
//     vault = await MockVault.deploy();
//     await vault.deployed();

//     const MockLoanManager = await ethers.getContractFactory("MockLoanManager");
//     loanManager = await MockLoanManager.deploy();
//     await loanManager.deployed();

//     const MockReceiptContract = await ethers.getContractFactory(
//       "MockReceiptContract"
//     );
//     receiptContract = await MockReceiptContract.deploy();
//     await receiptContract.deployed();

//     const MockWhiteListCollection = await ethers.getContractFactory(
//       "MockWhiteListCollection"
//     );
//     whiteListContract = await MockWhiteListCollection.deploy();
//     await whiteListContract.deployed();

//     // Deploy the main contract
//     const NettyWorthProxy = await ethers.getContractFactory("NettyWorthProxy");
//     nettyWorthProxy = await NettyWorthProxy.deploy();
//     await nettyWorthProxy.deployed();
//   });

//   describe("Initialization and Admin Settings", function () {
//     it("should initialize the contract correctly", async function () {
//       await nettyWorthProxy.initialize(
//         vault.address,
//         loanManager.address,
//         receiptContract.address,
//         whiteListContract.address,
//         adminWallet.address
//       );

//       expect(await nettyWorthProxy.vault()).to.equal(vault.address);
//       expect(await nettyWorthProxy.loanManager()).to.equal(loanManager.address);
//       expect(await nettyWorthProxy.receiptContract()).to.equal(
//         receiptContract.address
//       );
//       expect(await nettyWorthProxy.whiteListContract()).to.equal(
//         whiteListContract.address
//       );
//       expect(await nettyWorthProxy.adminWallet()).to.equal(adminWallet.address);
//     });

//     it("should allow the owner to update the admin fee", async function () {
//       await nettyWorthProxy.updateAdminFee(300);
//       expect(await nettyWorthProxy.adminFeeInBasisPoints()).to.equal(300);
//     });

//     it("should not allow a non-owner to update the admin fee", async function () {
//       await expect(
//         nettyWorthProxy.connect(otherUser).updateAdminFee(300)
//       ).to.be.revertedWith("Not the owner");
//     });

//     it("should allow the owner to update the admin wallet", async function () {
//       await nettyWorthProxy.setAdminWallet(otherUser.address);
//       expect(await nettyWorthProxy.adminWallet()).to.equal(otherUser.address);
//     });

//     it("should not allow a non-owner to update the admin wallet", async function () {
//       await expect(
//         nettyWorthProxy.connect(otherUser).setAdminWallet(otherUser.address)
//       ).to.be.revertedWith("Not the owner");
//     });
//   });

//   describe("Loan Offer Acceptance", function () {
//     it("should accept a loan offer when valid signatures are provided", async function () {
//       // Mock data for loan offer
//       const loanOffer = {
//         nftContractAddress: vault.address,
//         erc20TokenAddress: loanManager.address,
//         lender: lender.address,
//         borrower: borrower.address,
//         loanDuration: 3600,
//         nonce: 1,
//         loanAmount: ethers.utils.parseEther("10"),
//         aprBasisPoints: 500,
//         tokenId: 1,
//       };

//       // Mock signature (using random data for testing purposes)
//       const validSignature = "0x" + "a".repeat(130); // Mock a valid signature

//       // Assuming the mocks for validateSignatureApprovalOffer return true
//       await expect(
//         nettyWorthProxy
//           .connect(borrower)
//           .acceptLoanOffer(validSignature, loanOffer)
//       )
//         .to.emit(nettyWorthProxy, "LoanRepaid") // replace with correct event if needed
//         .withArgs(/*expected arguments based on emitted event*/);
//     });

//     it("should revert on invalid lender signature", async function () {
//       const loanOffer = {
//         nftContractAddress: vault.address,
//         erc20TokenAddress: loanManager.address,
//         lender: lender.address,
//         borrower: borrower.address,
//         loanDuration: 3600,
//         nonce: 2,
//         loanAmount: ethers.utils.parseEther("10"),
//         aprBasisPoints: 500,
//         tokenId: 2,
//       };

//       const invalidSignature = "0x" + "b".repeat(130); // Mock an invalid signature

//       await expect(
//         nettyWorthProxy
//           .connect(borrower)
//           .acceptLoanOffer(invalidSignature, loanOffer)
//       ).to.be.revertedWith("Invalid lender signature");
//     });
//   });

//   describe("Paying Back Loans", function () {
//     it("should allow a borrower to repay a loan", async function () {
//       // Mock loan setup
//       const loanId = 1;
//       const erc20Token = loanManager.address;

//       // Simulating the repayment process
//       await expect(
//         nettyWorthProxy.connect(borrower).payBackLoan(loanId, erc20Token)
//       )
//         .to.emit(nettyWorthProxy, "LoanRepaid")
//         .withArgs(
//           loanId,
//           vault.address,
//           1,
//           borrower.address,
//           lender.address,
//           ethers.utils.parseEther("10"),
//           erc20Token,
//           true
//         );
//     });

//     it("should revert if the borrower attempts to repay a closed loan", async function () {
//       const loanId = 1; // Assuming this loan is closed
//       const erc20Token = loanManager.address;

//       await expect(
//         nettyWorthProxy.connect(borrower).payBackLoan(loanId, erc20Token)
//       ).to.be.revertedWith("Loan is Paid");
//     });
//   });

//   describe("Loan Closure Due to Default", function () {
//     it("should allow a lender to forclose a defaulted loan", async function () {
//       const loanId = 1; // Mock loan ID for testing

//       await expect(nettyWorthProxy.connect(lender).forCloseLoan(loanId))
//         .to.emit(nettyWorthProxy, "LoanForClosed")
//         .withArgs(
//           loanId,
//           vault.address,
//           1,
//           borrower.address,
//           lender.address,
//           true
//         );
//     });

//     it("should revert if a loan is not yet defaulted", async function () {
//       const loanId = 2; // Assume this loan is not yet in default

//       await expect(
//         nettyWorthProxy.connect(lender).forCloseLoan(loanId)
//       ).to.be.revertedWith("User is not default yet::");
//     });
//   });
// });
