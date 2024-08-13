//attach 0x to the signer
const SECRET_SIGNER_PRIVATE_KEY =
	"0xe37107894ea14c592df2e4882c1e3faa7a98b30a09a543fa7fb02ab934dee280";
const { Web3 } = require("web3"); // Import the Web3 library

// Initialize a Web3 instance using the provider from ethers
const provider = new ethers.providers.JsonRpcProvider(); // Use the appropriate provider here
const web3 = new Web3(provider);

signDeposit = function (contract, tokenId, walletAddress) {
	const encoded = web3.eth.abi.encodeParameters(
		["address", "uint", "address"],
		[contract, tokenId, walletAddress]
	);
	return sign(encoded);
};

function sign(encoded) {
	const hash = web3.utils.keccak256(encoded);
	// Sign the hash with private key
	return web3.eth.accounts.sign(hash, SECRET_SIGNER_PRIVATE_KEY);
}

signOffer = function (
	tokenId,
	contract,
	erc20TokenAddress,
	loanAmount,
	interestRate,
	loanDuration,
	sender
) {
	const encoded = web3.eth.abi.encodeParameters(
		["uint", "address", "address", "uint", "uint", "uint", "address"],
		[
			tokenId,
			contract,
			erc20TokenAddress,
			loanAmount,
			interestRate,
			loanDuration,
			sender,
		]
	);
	return sign(encoded);
};

signCreateLoan = function (
	tokenId,
	contract,
	erc20TokenAddress,
	loanAmount,
	interestRate,
	loanDuration,
	lender,
	nonce,
	borrower
) {
	const encoded = web3.eth.abi.encodeParameters(
		[
			"uint",
			"address",
			"address",
			"uint",
			"uint",
			"uint",
			"address",
			"uint",
			"address",
		],
		[
			tokenId,
			contract,
			erc20TokenAddress,
			loanAmount,
			interestRate,
			loanDuration,
			lender,
			nonce,
			borrower,
		]
	);
	return sign(encoded);
};

function sign(encoded) {
	const hash = web3.utils.keccak256(encoded);
	// Sign the hash with private key
	return web3.eth.accounts.sign(hash, SECRET_SIGNER_PRIVATE_KEY);
}

module.exports = {
	signDeposit,
	signOffer,
	signCreateLoan,
};
