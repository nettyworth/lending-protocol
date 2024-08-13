require("dotenv").config();
require("@nomiclabs/hardhat-waffle");

module.exports = {
	networks: {
		goerli: {
			url: `https://goerli.infura.io/v3/5d5d153cab5c46f193cbb81bbddb5aa5`,
			accounts: [
				"e753ec0394dcaf65f0b2d65b57e3e6d77b4919e0557f89e2b831b182d08dfba1",
			],
		},
		local: {
			chainId: 1337,
			url: "http://127.0.0.1:7545",
			accounts: [
				"e753ec0394dcaf65f0b2d65b57e3e6d77b4919e0557f89e2b831b182d08dfba1",
			],
		},
	},
	solidity: {
		version: "0.8.19", // Your preferred Solidity compiler version
		settings: {
			optimizer: {
				enabled: true,
				runs: 200,
			},
		},
	},
};
