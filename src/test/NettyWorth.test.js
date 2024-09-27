// const { expect } = require("chai");
const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

console.log("start");
// describe(): Groups related test cases together, making it easier to manage and understand the tests.
describe("NettyWorth", async function () {
  let NettyWorthToken, nettyWorthToken;
  let NFTExample, nftExample;
  let CryptoVault, cryptoVault;
  let LoanManager, loanManager;
  let LoanReceipt, loanReceipt;
  let WhiteListCollection, whiteListCollection;
  let NettyWorthProxy, nettyWorthProxy;
  let owner, lender, borrower, admin, other;

  // beforeEach(): This function runs before each test case, setting up the contract environment, deploying contracts, and initializing states.
  before(async function () {
    // wallet addresses of the Nettyworth proxy users
    [owner, lender, borrower, admin, other] = await ethers.getSigners();

    // console.log("owner", owner.address);
    console.log("lender", lender.address);
    // console.log("borrower", borrower.address);
    // console.log("admin", admin.address);
    // console.log("other", other.address);

    //deploy the nettyworth proxy ERC29 token
    NettyWorthToken = await ethers.getContractFactory("NettyWorthToken");
    nettyWorthToken = await NettyWorthToken.deploy(
      ethers.parseUnits("100000000000", 18)
    );
    // await nettyWorthToken.deployed();

    //deploy the nettyworth proxy NFTExample
    NFTExample = await ethers.getContractFactory("NFTExample");
    nftExample = await NFTExample.deploy(
      "Test Nettyworth NFT",
      "TestNFT",
      "TNFT",
      100
    );
    // await nftExample.deployed();

    //deploy Crypto valut smart contract
    CryptoVault = await ethers.getContractFactory("CryptoVault");
    cryptoVault = await CryptoVault.deploy();
    // await cryptoVault.deployed();

    //deploy Loan Manager Smart contract
    LoanManager = await ethers.getContractFactory("LoanManager");
    loanManager = await LoanManager.deploy();
    // await loanManager.deployed();

    //deploy Loan Receipt smart contract
    LoanReceipt = await ethers.getContractFactory("LoanReceipt");
    loanReceipt = await LoanReceipt.deploy("Loan Receipt", "LRCPT");
    // await loanReceipt.deployed();

    //deploy Whitelist Collection smart contract
    WhiteListCollection = await ethers.getContractFactory(
      "WhiteListCollection"
    );
    whiteListCollection = await WhiteListCollection.deploy();
    // await whiteListCollection.deployed();

    await whiteListCollection.whiteListCollection([nftExample.getAddress()]);
    await whiteListCollection.whiteListErc20Token([
      nettyWorthToken.getAddress(),
    ]);

    //deploy nettyworth proxy smart contract
    NettyWorthProxy = await ethers.getContractFactory("NettyWorthProxy");
    nettyWorthProxy = await NettyWorthProxy.deploy();
    // await nettyWorthProxy.deployed();
    // console.log("\nnettyWorthToken", await nettyWorthToken.getAddress());
    // console.log("nftExample", await nftExample.getAddress());
    // console.log("cryptoVault", await cryptoVault.getAddress());
    // console.log("loanManager", await loanManager.getAddress());
    // console.log("loanReceipt", await loanReceipt.getAddress());
    // console.log(
    //   "whiteListCollectionawait",
    //   await whiteListCollection.getAddress()
    // );
    // console.log("nettyWorthProxys", await nettyWorthProxy.getAddress());

    //call the intialize function in nettyworth proxy smart contract
    await nettyWorthProxy.initialize(
      cryptoVault.getAddress(),
      loanManager.getAddress(),
      loanReceipt.getAddress(),
      whiteListCollection.getAddress(),
      admin.address
    );

    // const vaultaddress = await nettyWorthProxy.vault();
    // console.log("\nvaultaddress :", vaultaddress);
    // const Loanmanager = await nettyWorthProxy.loanManager();
    // console.log("loanManager :", Loanmanager);
    // const ReceiptContract = await nettyWorthProxy.receiptContract();
    // console.log("receiptContract :", ReceiptContract);
    // const WhiteListContract = await nettyWorthProxy.whiteListContract();
    // console.log("whiteListContract :", WhiteListContract);
    // const Owner = await nettyWorthProxy._owner();
    // console.log("Owner :", Owner);
    console.log("\nintialize successfully");

    // //set proxy manager in cryptovalut, loanmanager, loanReceipt and set nettyworth contract as a proxy manager
    await cryptoVault.setProxyManager(nettyWorthProxy.getAddress());
    await loanManager.setProxyManager(await nettyWorthProxy.getAddress());
    await loanReceipt.setProxyManager(await nettyWorthProxy.getAddress());

    console.log("Proxy Manager", await cryptoVault._proxy());
    console.log("Proxy Manager", await loanManager._proxy());
    console.log("Proxy Manager", await loanReceipt._proxy());

    await nettyWorthToken.transfer(
      lender.address,
      ethers.parseUnits("100000000", 18)
    );

    await nettyWorthToken
      .connect(lender)
      .approve(
        await cryptoVault.getAddress(),
        ethers.parseUnits("100000000", 18)
      );

    await nftExample.airdrop(borrower.address, 10);
    await nftExample
      .connect(borrower)
      .setApprovalForAll(await cryptoVault.getAddress(), true);

    await loanReceipt.setOpen(true);
  });

  describe("Initialization and Admin Settings", async function () {
    it("Should intialize the the proxy successfully", async function () {
      // await nettyWorthProxy.initialize(
      //   cryptoVault.getAddress(),
      //   loanManager.getAddress(),
      //   loanReceipt.getAddress(),
      //   whiteListCollection.getAddress(),
      //   admin.address
      // );

      expect(await nettyWorthProxy.vault(), "Vault address mismatch").to.equal(
        await cryptoVault.getAddress()
      );
      expect(
        await nettyWorthProxy.loanManager(),
        "Loan Manager address mismatch"
      ).to.equal(await loanManager.getAddress());

      expect(
        await nettyWorthProxy.receiptContract(),
        "Receipt contract address mismatch"
      ).to.equal(await loanReceipt.getAddress());

      expect(
        await nettyWorthProxy.whiteListContract(),
        "Whitelist contract address mismatch"
      ).to.equal(await whiteListCollection.getAddress());

      expect(
        await nettyWorthProxy.adminWallet(),
        "Admin address mismatch"
      ).to.equal(admin.address);

      console.log("Proxy initialized successfully and all addresses match!");
    });

    it("should allow the owner to update the admin fee", async function () {
      console.log("Owner", await nettyWorthProxy._owner());
      await nettyWorthProxy.updateAdminFee(300);
      expect(await nettyWorthProxy.adminFeeInBasisPoints()).to.equal(300);
      console.log("update admin fee successfully!");
    });

    it("should not allow a non-owner to update the admin fee", async function () {
      await expect(
        nettyWorthProxy.connect(other).updateAdminFee(300)
      ).to.be.revertedWith("Not the owner");
      console.log("not update admin fee successfully!");
    });

    it("should allow the owner to update the admin wallet", async function () {
      await nettyWorthProxy.setAdminWallet(other.address);
      expect(await nettyWorthProxy.adminWallet()).to.equal(other.address);
      console.log(
        "admin wallet successfully!",
        await nettyWorthProxy.adminWallet()
      );
    });

    it("should not allow a non-owner to update the admin wallet", async function () {
      await expect(
        nettyWorthProxy.connect(other).setAdminWallet(other.address)
      ).to.be.revertedWith("Not the owner");
      console.log("not allow anyone to update admin wallet successfully!");
    });
  });

  // ********************************Accept Loan Collection Offer*********************************/
  // describe("Accept Loan Collection Offer", async function () {
  //   async function createSignature(signer, data) {
  //     let abiencode = new ethers.AbiCoder();
  //     abiencode = abiencode.encode(data.types, data.values);
  //     const hash = ethers.keccak256(abiencode);
  //     const signature = await signer.signMessage(ethers.getBytes(hash));
  //     return signature;
  //   }
  //   it("should accept a loan Collection offer when valid signatures are provided", async function () {
  //     const tokenId = 1;
  //     const LoanCollectionOffer = {
  //       collectionAddress: await nftExample.getAddress(),
  //       erc20TokenAddress: await nettyWorthToken.getAddress(),
  //       lender: lender.address,
  //       loanAmount: ethers.parseUnits("10", 18),
  //       aprBasisPoints: 500,
  //       loanDuration: 1729332157,
  //       nonce: 1234,
  //     };

  //     const signature = await createSignature(lender, {
  //       types: [
  //         "address",
  //         "address",
  //         "address",
  //         "uint256",
  //         "uint256",
  //         "uint256",
  //         "uint256",
  //       ],
  //       values: [
  //         LoanCollectionOffer.collectionAddress,
  //         LoanCollectionOffer.erc20TokenAddress,
  //         LoanCollectionOffer.lender,
  //         LoanCollectionOffer.loanAmount,
  //         LoanCollectionOffer.aprBasisPoints,
  //         LoanCollectionOffer.loanDuration,
  //         LoanCollectionOffer.nonce,
  //       ],
  //     });

  //     console.log("signature++++++++++=", signature);

  //     const LoanCollectionOffer2 = {
  //       collectionAddress: await nftExample.getAddress(),
  //       erc20TokenAddress: await nettyWorthToken.getAddress(),
  //       lender: lender.address,
  //       loanAmount: ethers.parseUnits("10", 18),
  //       aprBasisPoints: 500,
  //       loanDuration: 1729332157,
  //       nonce: 1234,
  //     };

  //     expect(
  //       await nettyWorthToken.allowance(
  //         lender.address,
  //         await cryptoVault.getAddress()
  //       )
  //     ).to.equal(ethers.parseUnits("100000000", 18).toString());

  //     console.log(
  //       "ERC20 Allowance",
  //       await nettyWorthToken.allowance(
  //         lender.address,
  //         await cryptoVault.getAddress()
  //       )
  //     );

  //     expect(
  //       await nftExample.isApprovedForAll(
  //         borrower.address,
  //         await cryptoVault.getAddress()
  //       )
  //     ).to.equal(true);
  //     console.log(
  //       "NFT IS APPROVED OR NOT",
  //       await nftExample.isApprovedForAll(
  //         borrower.address,
  //         await cryptoVault.getAddress()
  //       )
  //     );

  //     expect(
  //       await nettyWorthProxy
  //         .connect(borrower)
  //         .acceptLoanCollectionOffer(signature, LoanCollectionOffer2, tokenId),
  //       "invalid signature"
  //     );
  //     // .to.equal(1, 2);
  //     console.log("borrower", borrower.address);
  //     console.log("crypto vault address", await cryptoVault.getAddress());
  //     console.log("NFT Owner after transfer ", await nftExample.ownerOf(1));
  //     console.log(
  //       "balance of Borrower After acceptOffer Call ",
  //       await nettyWorthToken.balanceOf(borrower.address)
  //     );

  //     // .to.emit(nettyWorthProxy, "LoanRepaid") // replace with correct event if needed
  //     // .withArgs(/*expected arguments based on emitted event*/);
  //   });
  // });

  // ********************************Accept Loan Request*********************************/

  // describe("Accept Loan Request", async function () {
  //   async function createSignature(signer, data) {
  //     let abiencode = new ethers.AbiCoder();
  //     abiencode = abiencode.encode(data.types, data.values);
  //     const hash = ethers.keccak256(abiencode);
  //     const signature = await signer.signMessage(ethers.getBytes(hash));
  //     return signature;
  //   }
  //   it("should accept a loanRequest when valid signatures are provided", async function () {
  //     const loanRequest = {
  //       tokenId: 1,
  //       nftContractAddress: await nftExample.getAddress(),
  //       erc20TokenAddress: await nettyWorthToken.getAddress(),
  //       borrower: borrower.address,
  //       loanAmount: ethers.parseUnits("10", 18),
  //       aprBasisPoints: 500,
  //       loanDuration: 1729332157,
  //       nonce: 1234,
  //     };

  //     const signature = await createSignature(borrower, {
  //       types: [
  //         "uint256",
  //         "address",
  //         "address",
  //         "address",
  //         "uint256",
  //         "uint256",
  //         "uint256",
  //         "uint256",
  //       ],
  //       values: [
  //         loanRequest.tokenId,
  //         loanRequest.nftContractAddress,
  //         loanRequest.erc20TokenAddress,
  //         loanRequest.borrower,
  //         loanRequest.loanAmount,
  //         loanRequest.aprBasisPoints,
  //         loanRequest.loanDuration,
  //         loanRequest.nonce,
  //       ],
  //     });

  //     console.log("signature++++++++++=", signature);

  //     const loanRequest2 = {
  //       tokenId: 1,
  //       nftContractAddress: await nftExample.getAddress(),
  //       erc20TokenAddress: await nettyWorthToken.getAddress(),
  //       borrower: borrower.address,
  //       loanAmount: ethers.parseUnits("10", 18),
  //       aprBasisPoints: 500,
  //       loanDuration: 1729332157,
  //       nonce: 1234,
  //     };

  //     expect(
  //       await nettyWorthToken.allowance(
  //         lender.address,
  //         await cryptoVault.getAddress()
  //       )
  //     ).to.equal(ethers.parseUnits("100000000", 18).toString());

  //     console.log(
  //       "ERC20 Allowance",
  //       await nettyWorthToken.allowance(
  //         lender.address,
  //         await cryptoVault.getAddress()
  //       )
  //     );

  //     expect(
  //       await nftExample.isApprovedForAll(
  //         borrower.address,
  //         await cryptoVault.getAddress()
  //       )
  //     ).to.equal(true);
  //     console.log(
  //       "NFT IS APPROVED OR NOT",
  //       await nftExample.isApprovedForAll(
  //         borrower.address,
  //         await cryptoVault.getAddress()
  //       )
  //     );

  //     // console.log("NFT Owner", await nftExample.ownerOf(1));
  //     // console.log("Contract is open or not :: ", await loanReceipt.open());
  //     // console.log("owner", owner.address);
  //     // console.log("lender", lender.address);
  //     // console.log("borrower", borrower.address);
  //     // console.log("admin", admin.address);
  //     // console.log("other", other.address);
  //     // console.log("\nnettyWorthToken", await nettyWorthToken.getAddress());
  //     // console.log("nftExample", await nftExample.getAddress());
  //     // console.log("cryptoVault", await cryptoVault.getAddress());
  //     // console.log("loanManager", await loanManager.getAddress());
  //     // console.log("loanReceipt", await loanReceipt.getAddress());
  //     // console.log(
  //     //   "whiteListCollectionawait",
  //     //   await whiteListCollection.getAddress()
  //     // );
  //     // console.log("nettyWorthProxys", await nettyWorthProxy.getAddress());

  //     expect(
  //       await nettyWorthProxy
  //         .connect(lender)
  //         .acceptLoanRequest(signature, loanRequest2),
  //       "invalid signature"
  //     );
  //     // .to.equal(1, 2);
  //     console.log("borrower", borrower.address);
  //     console.log("crypto vault address", await cryptoVault.getAddress());
  //     console.log("NFT Owner after transfer ", await nftExample.ownerOf(1));
  //     console.log(
  //       "balance of Borrower After acceptOffer Call ",
  //       await nettyWorthToken.balanceOf(borrower.address)
  //     );

  //     // await expect(
  //     //   nettyWorthProxy
  //     //     .connect(lender)
  //     //     .acceptLoanRequest(signature, loanRequest2),
  //     //   "invalid signature"
  //     // ).to.not.be.reverted;
  //     // const acceptloanRequest = nettyWorthProxy
  //     //   .connect(lender)
  //     //   .acceptLoanRequest(signature, loanRequest2);
  //     // console.log("acceptLoanRequest successfull", acceptloanRequest.hash);

  //     // .to.emit(nettyWorthProxy, "LoanRepaid") // replace with correct event if needed
  //     // .withArgs(/*expected arguments based on emitted event*/);
  //   });
  //   // it("should accept a LoanCollectionOffer when valid signatures are provided", async function () {
  //   //   console.log(
  //   //     " await nftExample.getAddress()",
  //   //     await nftExample.getAddress()
  //   //   );
  //   //   const tokenId = 1;
  //   //   const LoanCollectionOffer = {
  //   //     collectionAddress: await nftExample.getAddress(),
  //   //     erc20TokenAddress: await nettyWorthToken.getAddress(),
  //   //     lender: lender.address,
  //   //     loanAmount: ethers.parseUnits("10", 18),
  //   //     aprBasisPoints: 500,
  //   //     loanDuration: 1729332157,
  //   //     nonce: 1234,
  //   //   };

  //   //   console.log("lender.address 1", lender.address);

  //   //   const signature = await createSignature(lender, {
  //   //     types: [
  //   //       "address",
  //   //       "address",
  //   //       "address",
  //   //       "uint256",
  //   //       "uint256",
  //   //       "uint256",
  //   //       "uint256",
  //   //     ],
  //   //     values: [
  //   //       LoanCollectionOffer.collectionAddress,
  //   //       LoanCollectionOffer.erc20TokenAddress,
  //   //       LoanCollectionOffer.lender,
  //   //       LoanCollectionOffer.loanAmount,
  //   //       LoanCollectionOffer.aprBasisPoints,
  //   //       LoanCollectionOffer.loanDuration,
  //   //       LoanCollectionOffer.nonce,
  //   //     ],
  //   //   });

  //   //   console.log("signature collection++++++++++=", signature);

  //   //   const LoanCollectionOffer2 = {
  //   //     collectionAddress: await nftExample.getAddress(),
  //   //     erc20TokenAddress: await nettyWorthToken.getAddress(),
  //   //     lender: lender.address,
  //   //     loanAmount: ethers.parseUnits("10", 18),
  //   //     aprBasisPoints: 500,
  //   //     loanDuration: 1729332157,
  //   //     nonce: 1234,
  //   //   };

  //   //   expect(
  //   //     await nettyWorthToken.allowance(
  //   //       lender.address,
  //   //       await cryptoVault.getAddress()
  //   //     )
  //   //   ).to.equal(ethers.parseUnits("1000", 18).toString());

  //   //   console.log(
  //   //     "ERC20 Allowance",
  //   //     await nettyWorthToken.allowance(
  //   //       lender.address,
  //   //       await cryptoVault.getAddress()
  //   //     )
  //   //   );

  //   //   expect(
  //   //     await nftExample.isApprovedForAll(
  //   //       borrower.address,
  //   //       await cryptoVault.getAddress()
  //   //     )
  //   //   ).to.equal(true);

  //   //   console.log(
  //   //     "NFT IS APPROVED OR NOT",
  //   //     await nftExample.isApprovedForAll(
  //   //       borrower.address,
  //   //       await cryptoVault.getAddress()
  //   //     )
  //   //   );

  //   //   expect(
  //   //     await nettyWorthProxy
  //   //       .connect(borrower)
  //   //       .acceptLoanCollectionOffer(signature, LoanCollectionOffer2, tokenId),
  //   //     "invalid signature"
  //   //   );
  //   //   //   // .to.equal(1, 2);

  //   //   console.log("NFT Owner after transfer ", await nftExample.ownerOf(1));
  //   //   console.log(
  //   //     "balance of Borrower After acceptOffer Call ",
  //   //     await nettyWorthToken.balanceOf(borrower.address)
  //   //   );
  //   // });
  // });

  // //********************************Accept Loan Offer*********************************/
  describe("Accept Loan Offer", async function () {
    async function createSignature(signer, data) {
      let abiencode = new ethers.AbiCoder();
      abiencode = abiencode.encode(data.types, data.values);
      const hash = ethers.keccak256(abiencode);
      const signature = await signer.signMessage(ethers.getBytes(hash));
      return signature;
    }
    async function getloanid(tokenId, nonce) {
      const encodedData = ethers.solidityPacked(
        ["address", "address", "uint256", "uint256"],
        [borrower.address, await nftExample.getAddress(), tokenId, nonce]
      );

      const hash = ethers.keccak256(encodedData).toString();

      console.log("hash", hash);
      const loanId = BigInt(hash) & BigInt("0xffffffffffffffff");

      console.log("this is loanId", loanId);
      return loanId;
    }
    it("should accept a loan offer when valid signatures are provided", async function () {
      const LoanOffer = {
        tokenId: 1,
        nftContractAddress: await nftExample.getAddress(),
        erc20TokenAddress: await nettyWorthToken.getAddress(),
        lender: lender.address,
        borrower: borrower.address,
        loanAmount: ethers.parseUnits("10", 18),
        aprBasisPoints: 500,
        loanDuration: 1729332157,
        nonce: 12345,
      };

      const signature = await createSignature(lender, {
        types: [
          "uint256",
          "address",
          "address",
          "address",
          "address",
          "uint256",
          "uint256",
          "uint256",
          "uint256",
        ],
        values: [
          LoanOffer.tokenId,
          LoanOffer.nftContractAddress,
          LoanOffer.erc20TokenAddress,
          LoanOffer.lender,
          LoanOffer.borrower,
          LoanOffer.loanAmount,
          LoanOffer.aprBasisPoints,
          LoanOffer.loanDuration,
          LoanOffer.nonce,
        ],
      });

      console.log("signature++++++++++=", signature);

      const LoanOffer2 = {
        tokenId: 1,
        nftContractAddress: await nftExample.getAddress(),
        erc20TokenAddress: await nettyWorthToken.getAddress(),
        lender: lender.address,
        borrower: borrower.address,
        loanAmount: ethers.parseUnits("10", 18),
        aprBasisPoints: 500,
        loanDuration: 1729332157,
        nonce: 12345,
      };

      expect(
        await nettyWorthToken.allowance(
          lender.address,
          await cryptoVault.getAddress()
        )
      ).to.equal(ethers.parseUnits("100000000", 18).toString());

      console.log(
        "ERC20 Allowance",
        await nettyWorthToken.allowance(
          lender.address,
          await cryptoVault.getAddress()
        )
      );

      expect(
        await nftExample.isApprovedForAll(
          borrower.address,
          await cryptoVault.getAddress()
        )
      ).to.equal(true);
      console.log(
        "NFT IS APPROVED OR NOT",
        await nftExample.isApprovedForAll(
          borrower.address,
          await cryptoVault.getAddress()
        )
      );

      expect(
        await nettyWorthProxy
          .connect(borrower)
          .acceptLoanOffer(signature, LoanOffer2),
        "invalid signature"
      );
      // .to.equal(1, 2);
      console.log("crypto vault address", await cryptoVault.getAddress());
      console.log("borrower", borrower.address);

      console.log("NFT Owner after transfer ", await nftExample.ownerOf(1));
      console.log(
        "balance of Borrower After acceptOffer Call ",
        await nettyWorthToken.balanceOf(borrower.address)
      );

      // .to.emit(nettyWorthProxy, "LoanRepaid") // replace with correct event if needed
      // .withArgs(/*expected arguments based on emitted event*/);
    });

    it("Should return the correct loan and loanId", async function () {
      const LoanId = await getloanid(1, 12345);
      console.log("LoanId", LoanId);
      // Call the getLoan function
      const [loan, retrievedLoanId] = await loanManager.getLoan(
        await nftExample.getAddress(),
        1,
        borrower.address,
        12345
      );

      // Validate that the loanId matches
      expect(retrievedLoanId).to.equal(LoanId);

      // Validate that the loan details match what was stored
      // expect(loan.borrower).to.equal(loanDetails.borrower);
      // expect(loan.lender).to.equal(loanDetails.lender);
      // expect(loan.tokenId).to.equal(loanDetails.tokenId);
      // expect(loan.amount).to.equal(loanDetails.amount);
      // expect(loan.duration).to.equal(loanDetails.duration);
    });

    it("should allow the borrower to repay the loan to the lender", async function () {
      const loanId = await getloanid(1, 12345);
      console.log("loanId", loanId);
      console.log("borrower", borrower.address);

      console.log("crypto vault address", await cryptoVault.getAddress());

      console.log("NFT Owner after transfer ", await nftExample.ownerOf(1));

      const repaymentAmount = await loanManager.getPayoffAmount(loanId);
      console.log("repaymentAmount", repaymentAmount);

      await nettyWorthToken
        .connect(owner)
        .transfer(borrower.address, repaymentAmount);
      await nettyWorthToken
        .connect(borrower)
        .approve(await cryptoVault.getAddress(), repaymentAmount);

      const tx = await nettyWorthProxy
        .connect(borrower)
        .payBackLoan(loanId, await nettyWorthToken.getAddress());
      await tx.wait();

      // Check final balances to ensure repayment succeeded
      // expect(): aPrt of the Chai assertion library, used to make assertions about the contract’s state. For example, expect(await contract.balanceOf(address)).to.equal(value) checks that the balance matches the expected value.
      expect(await nettyWorthToken.balanceOf(lender.address)).to.be.gte(
        repaymentAmount
      );
    });
  });

  // it("Should set the right owner", async function () {
  //   // Get the owner address from the deployed contract
  //   const totalSupply = await nettyWorthToken.totalSupply();
  //   console.log(ethers.formatEther(totalSupply.toString()));
  //   expect(await nettyWorthToken.balanceOf(owner.address)).to.equal(
  //     totalSupply
  //   );
  // });

  // describe("Check LoanId", async function () {
  //   it("Should return the correct loan and loanId", async function () {
  //     const encodedData = ethers.solidityPacked(
  //       ["address", "address", "uint256", "uint256"],
  //       [borrower.address, await nftExample.getAddress(), 1, 1234]
  //     );

  //     const hash = ethers.keccak256(encodedData).toString();

  //     console.log("hash", hash);
  //     const loanId = BigInt(hash) & BigInt("0xffffffffffffffff");

  //     console.log("this is loanId", loanId);

  //     // Call the getLoan function
  //     const [loan, retrievedLoanId] = await loanManager.getLoan(
  //       await nftExample.getAddress(),
  //       1,
  //       borrower.address,
  //       1234
  //     );

  //     // Validate that the loanId matches
  //     expect(retrievedLoanId).to.equal(loanId);
  //   });
  // });

  // describe("Loan repayment from borrower", async function () {
  //   it("Should return the correct loan and loanId", async function () {
  //     const encodedData = ethers.solidityPacked(
  //       ["address", "address", "uint256", "uint256"],
  //       [borrower.address, await nftExample.getAddress(), 1, 1234]
  //     );

  //     const hash = ethers.keccak256(encodedData).toString();

  //     console.log("hash", hash);
  //     const loanId = BigInt(hash) & BigInt("0xffffffffffffffff");

  //     console.log("this is loanId", loanId);

  //     // Call the getLoan function
  //     const [loan, retrievedLoanId] = await loanManager.getLoan(
  //       await nftExample.getAddress(),
  //       1,
  //       borrower.address,
  //       1234
  //     );

  //     // Validate that the loanId matches
  //     expect(retrievedLoanId).to.equal(loanId);

  //     // Validate that the loan details match what was stored
  //     // expect(loan.borrower).to.equal(loanDetails.borrower);
  //     // expect(loan.lender).to.equal(loanDetails.lender);
  //     // expect(loan.tokenId).to.equal(loanDetails.tokenId);
  //     // expect(loan.amount).to.equal(loanDetails.amount);
  //     // expect(loan.duration).to.equal(loanDetails.duration);
  //   });
  // });

  //   // it(): Defines individual test cases. Each it() block should test a single aspect or function of the contract.
  // it("should allow the borrower to repay the loan to the lender", async function () {
  //   const loanId = 1; // Assume loanId 1 corresponds to the previous loan setup
  //   const repaymentAmount = ethers.utils.parseUnits("105", 18); // Mock repayment including principal + interest

  //   await nettyWorthToken
  //     .connect(owner)
  //     .transfer(borrower.address, repaymentAmount);
  //   await nettyWorthToken
  //     .connect(borrower)
  //     .approve(nettyWorthProxy.address, repaymentAmount);

  //   const tx = await nettyWorthProxy
  //     .connect(borrower)
  //     .payBackLoan(loanId, nettyWorthToken.address);
  //   await tx.wait();

  //   // Check final balances to ensure repayment succeeded
  //   // expect(): aPrt of the Chai assertion library, used to make assertions about the contract’s state. For example, expect(await contract.balanceOf(address)).to.equal(value) checks that the balance matches the expected value.
  //   expect(await nettyWorthToken.balanceOf(lender.address)).to.be.gte(
  //     repaymentAmount
  //   );
  // });
  // });
});

// Commonly Used Functions in Testing

// beforeEach(): This function runs before each test case, setting up the contract environment, deploying contracts, and initializing states.

// describe(): Groups related test cases together, making it easier to manage and understand the tests.

// it(): Defines individual test cases. Each it() block should test a single aspect or function of the contract.

// expect(): aPrt of the Chai assertion library, used to make assertions about the contract’s state. For example, expect(await contract.balanceOf(address)).to.equal(value) checks that the balance matches the expected value.

// Contract Call Functions: Functions such as contract.functionName(), contract.connect(signer).functionName(), and contract.callStatic.functionName() are used to interact with the contract during testing.

// Event Emission Checks: Use await expect(transaction).to.emit(contract, "EventName") to check if a particular event was emitted during the transaction.

// Error Handling: Use await expect(transaction).to.be.revertedWith("Error Message") to verify that transactions revert correctly under specific conditions.

// console.log("owner", owner.address);
// console.log("lender", lender.address);
// console.log("borrower", borrower.address);
// console.log("admin", admin.address);
// console.log("other", other.address);
// console.log("\nnettyWorthToken", await nettyWorthToken.getAddress());
// console.log("nftExample", await nftExample.getAddress());
// console.log("cryptoVault", await cryptoVault.getAddress());
// console.log("loanManager", await loanManager.getAddress());
// console.log("loanReceipt", await loanReceipt.getAddress());
// console.log(
//   "whiteListCollectionawait",
//   await whiteListCollection.getAddress()
// );
// console.log("nettyWorthProxys", await nettyWorthProxy.getAddress());
