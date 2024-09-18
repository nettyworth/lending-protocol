// hardhat.config.js

require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
const {ADMIN_PRIVATE_KEY,
  QUICKNODE_SEPOLIA_URL,
  // QUICKNODE_MAINNET_URL,
  // QUICKNODE_HOLESKY_URL,
  ETHERSCAN_API_KEY } =  process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks: {
    hardhat: {},
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    // sepolia: {
    //   url: process.env.QUICKNODE_SEPOLIA_URL,
    //   accounts: [process.env.PRIVATE_KEY]
    // },
    // holesky: {
    //   url: process.env.QUICKNODE_HOLESKY_URL,
    //   accounts: [process.env.PRIVATE_KEY]
    // },
    // mainnet: {
    //   url: process.env.QUICKNODE_MAINNET_URL,
    //   accounts: [process.env.PRIVATE_KEY]
    sepolia: {
      url: QUICKNODE_SEPOLIA_URL,
      accounts: [ADMIN_PRIVATE_KEY]
    }
  //   holesky: {
  //     url: QUICKNODE_HOLESKY_URL,
  //     accounts: [ADMIN_PRIVATE_KEY]
  //   },
  //   mainnet: {
  //     url: QUICKNODE_MAINNET_URL,
  //     accounts: [ADMIN_PRIVATE_KEY]
  // },
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
    apiKey: ETHERSCAN_API_KEY
  },
};
// etherscan: {
//   apiKey: process.env.ETHERSCAN_API_KEY
// }
// };
