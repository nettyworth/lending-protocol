// hardhat.config.js

require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */

const settings = {
  optimizer: {
    enabled: true,
    runs: 200,
  },
};
module.exports = {
  networks: {
    hardhat: {},
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    sepolia: {
      url: process.env.QUICKNODE_SEPOLIA_URL,
      accounts: [process.env.PRIVATE_KEY]
    },
    holesky: {
      url: process.env.QUICKNODE_HOLESKY_URL,
      accounts: [process.env.PRIVATE_KEY]
    },
    mainnet: {
      url: process.env.QUICKNODE_MAINNET_URL,
      accounts: [process.env.PRIVATE_KEY]
  },
},
  solidity: {
    compilers: [{ version: '0.8.24', settings }],
  },
  paths: {
    sources: 'src/contracts',
    tests: 'src/test',
    artifacts: 'src/artifacts',
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  },
};

