const { assert } = require("chai");
const { ethers } = require("hardhat");

describe("Deployment", function () {
	let CryptoVault;
	let cryptoVaultDeployed;

	before(async function () {
		CryptoVault = await ethers.getContractFactory("CryptoVault");
		cryptoVaultDeployed = await CryptoVault.deploy();
	});

	it("Should set the right owner", async function () {
		// Get the owner address from the deployed contract
		const owner = await cryptoVaultDeployed.owner();
	});
});
