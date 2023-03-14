import '@nomicfoundation/hardhat-toolbox';

module.exports = {
  networks: {
    hardhat: {

    },
  },
  solidity: {
    version: "0.8.16",
    settings: {
      optimizer: {
        enabled: true,
        runs: 7777
      }
    }
  },
  gasReporter: {
    enabled: true
  }
};
