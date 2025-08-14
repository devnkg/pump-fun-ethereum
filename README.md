
# Foundry Project

**Foundry** is a blazing-fast, portable, and modular toolkit for Ethereum application development written in Rust.

It consists of the following tools:

- **Forge** – Ethereum testing framework (like Truffle, Hardhat, and DappTools).
- **Cast** – Swiss army knife for interacting with EVM smart contracts, sending transactions, and getting chain data.
- **Anvil** – Local Ethereum node (similar to Ganache or Hardhat Network).
- **Chisel** – Fast, utilitarian, and verbose Solidity REPL.

---

## 📚 Documentation
Official docs: [https://book.getfoundry.sh/](https://book.getfoundry.sh/)

---

## 🚀 Quick Start

### 1️⃣ Build
```bash
forge install
````

```bash
forge build
````

### 2️⃣ Test

```bash
forge test
```

### 3️⃣ Deploy

```bash
forge script script/BondingFactoryScript.s.sol:BondingFactory \
  --rpc-url https://mainnet.infura.io/v3/<your_project_id> \
  --private-key <your_private_key> \
  --broadcast \
  --verify \
  --etherscan-api-key <your_etherscan_api_key> \
  -vvvv
```

---

## 🛠 Additional Commands

### Format Code

```bash
forge fmt
```

### Take Gas Snapshots

```bash
forge snapshot
```

### Start Local Node

```bash
anvil
```

### Use Cast

```bash
cast <subcommand>
```

---

## 📖 Help

```bash
forge --help
anvil --help
cast --help
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).


