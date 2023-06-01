require("dotenv").config()

require("@nomiclabs/hardhat-etherscan")
require("@nomiclabs/hardhat-waffle")
require("hardhat-gas-reporter")
require("solidity-coverage")
require("hardhat-deploy")

const PRIVATE_KEY = process.env.PRIVATE_KEY || "0xKey"
const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY || "key"
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "key"

module.exports = {
    solidity: {
        version: "0.8.17",
        settings: {
            optimizer: {
                enabled: true,
                runs: 999,
            },
            viaIR: false,
        },
    },
    defaultNetwork: "hardhat",
    networks: {
        goerli: {
            chainId: 5,
            url: `${
                process.env.RPC_URL ||
                `https://goerli.infura.io/v3/${process.env.INFURA_API_KEY}`
            }`,
            ...(process.env.TESTNET_PRIVATE_KEY
                ? { accounts: [process.env.TESTNET_PRIVATE_KEY] }
                : {}),
            gas: "auto",
            gasPrice: "auto",
            gasMultiplier: 1.2,
        },
    },
    gasReporter: {
        enabled: true,
        outputFile: "gas-report.txt",
        noColors: true,
        currency: "USD",
        coinmarketcap: COINMARKETCAP_API_KEY,
        token: "ETH",
    },
    etherscan: {
        apiKey: process.env.ETHERSCAN_API_KEY,
    },
    namedAccounts: {
        deployer: {
            default: 0, // here this will by default take the first account as deployer
            1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
        },
    },
}
