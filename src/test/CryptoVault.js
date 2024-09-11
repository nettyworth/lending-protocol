const assert = require("assert"); // Import the assertion library
const { ethers, network } = require("hardhat");
require("dotenv").config();
const { ERC20HolderWallet, ERC721HolderWallet, gasLimit, PUBLIC_KEY } =
	process.env;

const customProviderUrl = "http://localhost:7545"; // Replace with your custom provider URL
const customProvider = new ethers.providers.JsonRpcProvider(customProviderUrl);
const signerUtil = require("../../utils/contractSigner");
const totalMinted = 10;

describe("CryptoVault", function () {
	let CryptoVault;
	let cryptoVaultDeployed;
	let testToken, testTokenDeployed;
	let ERC721Token, erc721TokenDeployed;

	let LoanReceipt, loanReceiptDeployed;
	let LoanManager, loanManagerDeployed;
	let NettyWorthProxy, nettyWorthProxyDeployed;

	before(async function () {
		CryptoVault = await ethers.getContractFactory("CryptoVault");
		cryptoVaultDeployed = await CryptoVault.deploy();

		LoanReceipt = await ethers.getContractFactory("LoanReceipt");
		loanReceiptDeployed = await LoanReceipt.deploy("Netty Receipt", "NWR");

		LoanManager = await ethers.getContractFactory("LoanManager");
		loanManagerDeployed = await LoanManager.deploy();

		loanManagerDeployed.on(
			"LoanCreated",
			(
				loanId,
				nftContract,
				tokenId,
				borrower,
				lender,
				loanAmount,
				interestRate,
				loanDuration,
				erc20,
				totalPaid,
				loanInitialTime,
				isClosed,
				isApproved
			) => {
				console.log("LoanCreated11s event triggered with the following data:");
				console.log("Loan ID:", loanId);
				console.log("NFT Contract:", nftContract, erc721TokenDeployed.address);
				console.log("Token ID:", tokenId, 5);
				console.log("Borrower:", borrower);
				console.log("Lender:", lender);
				console.log("Loan Amount:", loanAmount);
				console.log("Interest Rate:", interestRate);
				console.log("Loan Duration:", loanDuration);
				console.log("Total Paid:", totalPaid);
				console.log("ERC20 :", erc20);
				console.log("Loan Initial Time:", loanInitialTime);
				console.log("Is Closed:", isClosed);
				console.log("Is Approved:", isApproved);
			}
		);

		NettyWorthProxy = await ethers.getContractFactory("NettyWorthProxy");
		nettyWorthProxyDeployed = await NettyWorthProxy.deploy();

		testToken = await ethers.getContractFactory("MyToken");
		testTokenDeployed = await testToken.deploy(1000);

		ERC721Token = await ethers.getContractFactory("TestToken");
		erc721TokenDeployed = await ERC721Token.deploy(
			"ERC721",
			"Token",
			"TT",
			1000
		);

		const owner = await cryptoVaultDeployed.owner();
		const signer = customProvider.getSigner(owner);

		const tx = await erc721TokenDeployed
			.connect(signer)
			.airdrop(ERC721HolderWallet, totalMinted, {
				gasLimit: gasLimit,
			});
		await tx.wait();
	});

	beforeEach(async function () {});

	it("Should initialize the Loan Receipt Contract", async function () {
		const tx = await loanReceiptDeployed.setProxyManager(
			nettyWorthProxyDeployed.address
		);

		await tx.wait();

		assert.strictEqual(
			await nettyWorthProxyDeployed.address,
			await loanReceiptDeployed._proxy(),
			"Proxy not set correctly"
		);
	});

	it("Should initialize the CryptoVault Contract", async function () {
		const tx = await cryptoVaultDeployed.setProxyManager(
			nettyWorthProxyDeployed.address
		);
		await tx.wait();
		assert.strictEqual(
			await nettyWorthProxyDeployed.address,
			await cryptoVaultDeployed._proxy(),
			"Proxy not set correctly"
		);
	});

	it("Should initialize the Loan Manager Contract", async function () {
		const tx = await loanManagerDeployed.setProxyManager(
			nettyWorthProxyDeployed.address
		);
		await tx.wait();
		assert.strictEqual(
			await nettyWorthProxyDeployed.address,
			await loanManagerDeployed._proxy(),
			"Proxy not set correctly"
		);
	});

	it("Should Open the Loan Receipt Contract", async function () {
		const tx = await loanReceiptDeployed.setOpen(true);

		await tx.wait();

		assert.strictEqual(
			true,
			await loanReceiptDeployed.open(),
			"Loan Receipt not opening correctly"
		);
	});

	it("Should initialize the NettyWorthProxy Contract", async function () {
		const tx = await nettyWorthProxyDeployed.initialize(
			cryptoVaultDeployed.address,
			loanManagerDeployed.address,
			loanReceiptDeployed.address
		);

		await tx.wait();

		assert.strictEqual(
			await nettyWorthProxyDeployed.vault(),
			cryptoVaultDeployed.address,
			"Vault not set correctly"
		);

		assert.strictEqual(
			await nettyWorthProxyDeployed.loanManager(),
			loanManagerDeployed.address,
			"Loan Manager not set correctly"
		);

		assert.strictEqual(
			await nettyWorthProxyDeployed.receiptContract(),
			loanReceiptDeployed.address,
			"Loan Receipt not set correctly"
		);

		const proxySecretTx = await nettyWorthProxyDeployed.setSigner(PUBLIC_KEY);
		await proxySecretTx.wait();

		assert.strictEqual(
			await nettyWorthProxyDeployed.secret(),
			PUBLIC_KEY,
			"PUBLIC SIGNER NOT SET CORRECTLY"
		);
	});

	it("Should have the right owner", async function () {
		const owner = await cryptoVaultDeployed.owner();
		const privateKey = network.config.accounts[0];
		const wallet = new ethers.Wallet(privateKey);
		const address = wallet.address;
		assert.strictEqual(owner, address, "Owner not set correctly");
	});

	it("Should allow depositing an ERC721 token", async function () {
		const signer = customProvider.getSigner(ERC721HolderWallet);
		const tx = await erc721TokenDeployed
			.connect(signer)
			.transferFrom(ERC721HolderWallet, cryptoVaultDeployed.address, 1, {
				gasLimit: gasLimit,
			});

		await tx.wait();
		console.log("Transfer to the Vault Complete.");
		const balanceOf = await erc721TokenDeployed.balanceOf(ERC721HolderWallet);
		const balanceCryptoVault = await erc721TokenDeployed.balanceOf(
			cryptoVaultDeployed.address
		);

		assert.strictEqual(
			parseInt(balanceOf),
			totalMinted - 1,
			"Original ERC721 Holder should have -1"
		);
		assert.strictEqual(
			parseInt(balanceCryptoVault),
			1,
			"CryptoVault should have 1 ERC721"
		);
	});

	it("Should fail depositing an ERC721 token through the NettyWorthProxy without the security tunning", async function () {
		const signer = customProvider.getSigner(ERC721HolderWallet);

		tokenID = 2;
		const signTx = signerUtil.signDeposit(
			erc721TokenDeployed.address,
			2,
			ERC721HolderWallet
		);

		nettyWorthProxyDeployed.validateSignature(signTx.signature);

		//There is a need for an approveAll using the contractId, the owner abd the proxyAddress
		const approveAllTx = await erc721TokenDeployed
			.connect(signer)
			.approve(nettyWorthProxyDeployed.address, tokenID, {
				gasLimit: gasLimit,
			});

		const tx = await nettyWorthProxyDeployed
			.connect(signer)
			.depositToEscrow(signTx.signature, erc721TokenDeployed.address, tokenID, {
				gasLimit: gasLimit,
			});

		await tx.wait();
		console.log("Transfer to the Vault Complete.");

		// Transfer ERC721 token using the signer
		try {
			const balanceOf = await erc721TokenDeployed.balanceOf(ERC721HolderWallet);
			const balanceCryptoVault = await erc721TokenDeployed.balanceOf(
				cryptoVaultDeployed.address
			);
		} catch (error) {
			assert(
				error.message.includes(
					"VM Exception while processing transaction: revert"
				)
			);
		}
	});

	it("Should initialize the CryptoVault Contract", async function () {
		const tx = await cryptoVaultDeployed.setProxyManager(
			nettyWorthProxyDeployed.address
		);
		await tx.wait();
		assert.strictEqual(
			await nettyWorthProxyDeployed.address,
			await cryptoVaultDeployed._proxy(),
			"Proxy not set correctly"
		);
	});

	it("Should allow depositing an ERC721 token through the NettyWorthProxy", async function () {
		const setProxyTx = await cryptoVaultDeployed.setProxyManager(
			nettyWorthProxyDeployed.address
		);
		await setProxyTx.wait();
		assert.strictEqual(
			await nettyWorthProxyDeployed.address,
			await cryptoVaultDeployed._proxy(),
			"Proxy not set correctly"
		);

		const signer = customProvider.getSigner(ERC721HolderWallet);

		tokenID = 3;
		const signTx = signerUtil.signDeposit(
			erc721TokenDeployed.address,
			tokenID,
			ERC721HolderWallet
		);

		nettyWorthProxyDeployed.validateSignature(signTx.signature);

		//There is a need for an approve using the contractId, the owner and the proxyAddress
		const approveAllTx = await erc721TokenDeployed
			.connect(signer)
			.approve(nettyWorthProxyDeployed.address, tokenID, {
				gasLimit: gasLimit,
			});

		const tx = await nettyWorthProxyDeployed
			.connect(signer)
			.depositToEscrow(signTx.signature, erc721TokenDeployed.address, tokenID, {
				gasLimit: gasLimit,
			});

		await tx.wait();
		console.log("Transfer to the Vault Complete.");

		// Transfer ERC721 token using the signer
		const balanceOf = await erc721TokenDeployed.balanceOf(ERC721HolderWallet);
		const balanceCryptoVault = await erc721TokenDeployed.balanceOf(
			cryptoVaultDeployed.address
		);

		assert.strictEqual(
			parseInt(balanceOf),
			totalMinted - 3,
			"Original ERC721 Holder should have -1"
		);
		assert.strictEqual(
			parseInt(balanceCryptoVault),
			3,
			"CryptoVault should have 1 ERC721"
		);
	});

	it("Should prevent depositing the same token twice", async function () {
		const signer = customProvider.getSigner(ERC721HolderWallet);
		try {
			const tx = await erc721TokenDeployed
				.connect(signer)
				.transferFrom(ERC721HolderWallet, cryptoVaultDeployed.address, 1, {
					gasLimit: gasLimit,
				});

			await tx.wait();
			assert.fail("Transaction did not revert as expected");
		} catch (error) {
			assert(
				error.message.includes(
					"VM Exception while processing transaction: revert"
				)
			);
		}
	});

	// Withdrawal tests
	it("Should allow withdrawing an ERC721 token from the ProxyManager", async function () {
		// Perform assertions for withdrawing an ERC721 token
	});

	it("Should prevent withdrawing an unowned token", async function () {
		// Perform assertions for preventing unauthorized withdrawal
	});

	// Receipt attachment tests
	it("Should attach a receipt to an ERC721 token", async function () {
		const setProxyTx = await cryptoVaultDeployed.setProxyManager(
			nettyWorthProxyDeployed.address
		);
		await setProxyTx.wait();
		assert.strictEqual(
			await nettyWorthProxyDeployed.address,
			await cryptoVaultDeployed._proxy(),
			"Proxy not set correctly"
		);

		const signer = customProvider.getSigner(ERC721HolderWallet);

		tokenID = 5;
		const signTx = signerUtil.signDeposit(
			erc721TokenDeployed.address,
			tokenID,
			ERC721HolderWallet
		);

		nettyWorthProxyDeployed.validateSignature(signTx.signature);

		//There is a need for an approveAll using the contractId, the owner abd the proxyAddress
		const approveAllTx = await erc721TokenDeployed
			.connect(signer)
			.approve(nettyWorthProxyDeployed.address, tokenID, {
				gasLimit: gasLimit,
			});

		const tx = await nettyWorthProxyDeployed
			.connect(signer)
			.depositToEscrow(signTx.signature, erc721TokenDeployed.address, tokenID, {
				gasLimit: gasLimit,
			});

		await tx.wait();
		console.log("Transfer to the Vault Complete.");

		// Transfer ERC721 token using the signer
		const balanceOf = await erc721TokenDeployed.balanceOf(ERC721HolderWallet);
		const balanceCryptoVault = await erc721TokenDeployed.balanceOf(
			cryptoVaultDeployed.address
		);

		assert.strictEqual(
			parseInt(balanceOf),
			totalMinted - 4,
			"Original ERC721 Holder should have -1"
		);
		assert.strictEqual(
			parseInt(balanceCryptoVault),
			4,
			"CryptoVault should have 1 ERC721"
		);

		const balanceOfReceipt = await loanReceiptDeployed.balanceOf(
			ERC721HolderWallet
		);

		assert.strictEqual(
			parseInt(balanceOfReceipt),
			3,
			"ERC721Holder should have 3 Receipts"
		);
	});

	it("Should initialize the ERC20 Contract and made an initial deposit to ERC20Holder Account", async function () {
		// Transfer tokens to the recipient
		const ERC20Signer = customProvider.getSigner(ERC20HolderWallet);
		testTokenDeployed.connect(ERC20Signer).transfer(ERC721HolderWallet, 500, {
			gasLimit: gasLimit,
		});

		const finalBalance = await testTokenDeployed.balanceOf(ERC20HolderWallet);
		assert.strictEqual(parseInt(finalBalance), 2500, "Balance should be 2500");
	});

	it("Should create a loan offer", async function () {
		// Perform assertions for creating a loan offer
		const signerERC20Holder = customProvider.getSigner(ERC20HolderWallet);
		const tokenId = 5;
		//Interest expressed in XX.XX format (in this case 20%)
		const interestRate = 2000;

		const loanAmount = 2000;

		// Loan Duration expressed in seconds
		const loanDuration = 604800;

		const randomNum = 1;

		const { signature } = signerUtil.signOffer(
			tokenId,
			erc721TokenDeployed.address,
			testTokenDeployed.address,
			loanAmount,
			interestRate,
			loanDuration,
			ERC20HolderWallet
		);

		//If success, save the information in the server side and
		// show it to the borrowers/lenders through the FE
		const tx = await nettyWorthProxyDeployed
			.connect(signerERC20Holder)
			.makeOffer(
				signature,
				tokenId,
				erc721TokenDeployed.address,
				testTokenDeployed.address,
				loanAmount,
				interestRate,
				loanDuration,
				{
					gasLimit: gasLimit,
				}
			);
	});

	it("Should approve a loan offer", async function () {
		// Check the allowance (How much ERC20 the proxy can spend of the user's behalf);

		const ERC20Signer = customProvider.getSigner(ERC20HolderWallet);
		const signer = customProvider.getSigner(ERC721HolderWallet);

		const tx = await testTokenDeployed
			.connect(ERC20Signer)
			.approve(ERC721HolderWallet, 2000, {
				gasLimit,
			});
		allowanceAmount = await testTokenDeployed.allowance(
			ERC20HolderWallet,
			ERC721HolderWallet
		);

		assert.strictEqual(
			parseInt(allowanceAmount),
			2000,
			"Allowance should be 2000"
		);

		const tokenId = 5;
		//Interest expressed in XX.XX format (in this case 20%)
		const interestRate = 2000;

		const loanAmount = 2000;

		// Loan Duration expressed in seconds
		const loanDuration = 604800;

		const _nonce = 1;

		console.log(
			tokenId,
			erc721TokenDeployed.address,
			testTokenDeployed.address,
			loanAmount,
			interestRate,
			loanDuration,
			ERC20HolderWallet,
			_nonce,
			ERC721HolderWallet
		);

		const { signature } = signerUtil.signCreateLoan(
			tokenId,
			erc721TokenDeployed.address,
			testTokenDeployed.address,
			loanAmount,
			interestRate,
			loanDuration,
			ERC20HolderWallet,
			_nonce,
			ERC721HolderWallet
		);

		const approvedLoan = await nettyWorthProxyDeployed
			.connect(signer)
			.approveLoan(
				signature,
				tokenId,
				erc721TokenDeployed.address,
				testTokenDeployed.address,
				loanAmount,
				interestRate,
				loanDuration,
				ERC20HolderWallet,
				_nonce,
				{
					gasLimit,
				}
			);

		console.log("Transaction Hash:", approvedLoan.hash);

		// Perform assertions for approving a loan offer
	});

	it("Should make a payment", async function () {
		// Perform assertions for making a payment
	});

	it("Should redeem a loan", async function () {
		// Perform assertions for redeeming a loan
	});

	// Add more tests for other functions as needed
	it("Should allow the borrower to borrow an ERC721 token", async function () {
		// Perform assertions for borrowing an ERC721 token
	});

	it("Should prevent another user from borrowing the same token", async function () {
		// Perform assertions for preventing unauthorized borrowing
	});

	it("Should allow the borrower to return the borrowed token", async function () {
		// Perform assertions for returning the borrowed token
	});

	it("Should prevent the borrower from returning the same token twice", async function () {
		// Perform assertions for preventing double return
	});

	it("Should allow the owner to retrieve the token after it's returned", async function () {
		// Perform assertions for owner retrieving the token
	});
});
