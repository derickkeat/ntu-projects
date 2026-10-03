[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/76QeiOs7)
# 2024-Fall-DeFi-HW4

## Question 1
> Please explain the inner workings of ZK Rollups and Optimistic Rollups and compare the differences between these rollup structures. Additionally, explain the differences between ZK Rollups, Volition, and Validium modes. (5 pt)

ZK Rollups are rollups where validators prove a transaction via Zero-Knowledge Proofs. Optimistic Rollups wait for challenges for a certain period, and the transaction data will be added to mainnet if unchallenged. ZK Rollups assume all transactions are false until proven valid, while Optimistic Rollups assume all transaction are true unless proven false. Data in validiums are stored off-chain, while data in ZK Rollups are stored on-chain. Therefore, Validium requires some trust. Volition let the users to choose where to store the data (on-chain or off-chain).

## Question 2
> According to L2 Beat, there are multiple stages for a Layer 2. What are the criteria for each stage, and what is the current status of the Layer 2 solutions in use? (5pt)
Stage 0 - Full Training Wheels: The rollups are still run by the operators.
Stage 1 - Limited Training Wheels: The rollups are run by smart contracts, while a Security Council might remain in place to find potential bugs.
Stage 2 - No Training Wheels: The rollups are fully run by smart contracts.

Most of the current layer 2 are still in Stage 0.

## Question 3
> Layer 2 solutions aim to address scaling issues in the Ethereum ecosystem, but they introduce liquidity fragmentation, which leads to interoperability challenges. Cross-chain bridges can help address these issues. Modern cross-chain bridges can be categorized into burn-and-mint, lock-and-mint, and lock-and-unlock mechanisms. Please analyze two cross-chain bridge structures (e.g., LayerZero, Wormhole and more) with distinct underlying mechanisms. (5 pt)
Arbitrum - Arbitrum uses burn-and-mint mechanism for USDC as Circle launched USDC natively on Arbitrum One.

Wormhole - Wormhole uses lock-and-mint mechanism

## Question 4
> Cross-chain bridges have suffered significant losses due to security breaches. For example, in 2021, PolyNetwork experienced a $611 million exploit, BNB Bridge faced a $586 million exploit, and Wormhole was attacked for $326 million. Please analyze the vulnerabilities in a cross-chain bridge structure, providing code examples to illustrate the issues. (5 pt)

## Question 5
> User experience is key to the mass adoption of blockchain. Currently, intent-based solutions are popular. What is an intent, and how does it differ from a cross-chain bridge? (5 pt)
Intent-based solution allows user to access to blockchain feature without understanding the underlying blockchain infrastructure. All we need to know is what users want to achieve. Then complete the execute for them.

## Question 6
> The ongoing bull market is marked by an increase in both the number and total losses from phishing scams. Please explain how permit and permit2 work, along with examples of phishing scams related to these operaitons. (5 pt)
`permit` makes approving off-chain possible, which reduces transaction and saves gas fee. `permit2` does the same things, but it has additional feature such as allowing user to sign a single approval that works across multiple contracts. It also enables approving multiple tokens at once or setting allowances for multiple spender in a single action.

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
