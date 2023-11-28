import { HardhatUserConfig } from "hardhat/config";

import "@matterlabs/hardhat-zksync-deploy";
import "@matterlabs/hardhat-zksync-solc";

import "@matterlabs/hardhat-zksync-verify";

import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
require('dotenv').config();
// dynamically changes endpoints for local tests
const zkSyncTestnet =
      {
        url: "https://testnet.era.zksync.dev",
        ethNetwork: "goerli",
        zksync: true,
        // contract verification endpoint
        verifyURL:
          "https://zksync2-testnet-explorer.zksync.dev/contract_verification",
      };

const config: HardhatUserConfig = {
  zksolc: {
    version: "1.3.16",
    settings: {},
  },
  defaultNetwork: "zkSyncTestnet",
  networks: {
    hardhat: {
      zksync: false,
    },
    zkSyncTestnet,
    mumbai: {
      url: "https://polygon-mumbai-bor.publicnode.com",
      accounts: [process.env.WALLET_PRIVATE_KEY]
    },

    goerli: {
      url: "https://ethereum-goerli.publicnode.com",
      accounts: [process.env.WALLET_PRIVATE_KEY]
    },

  },
  solidity: {
    version: "0.8.17",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  etherscan : {
    apiKey: process.env.API_KEY_MATIC
  }
};

export default config;
