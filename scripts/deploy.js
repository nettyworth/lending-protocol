require("dotenv").config();
const { ethers } = require("hardhat");

async function main() {
	try {
		const factory = await ethers.getContractFactory("CryptoVault");
		const contract = await factory.deploy();

		await contract.deployed();

		//Waiting to be mined.
		await contract.deployTransaction.wait(3);

		console.log("Deployed CryptoVault");

		// run("verify:verify", {
		// 	address: contract.address,
		// 	contract: "contracts/VaultContractObj.sol:MyCryptoVault",
		// 	constructorArguments: [],
		// });
	} catch (error) {
		console.log(error);
	}
}

main();
