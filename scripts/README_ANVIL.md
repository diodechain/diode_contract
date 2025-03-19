# Anvil Deployment for ZTNAPerimeterRegistry

This directory contains scripts to deploy the ZTNAPerimeterRegistry contract to a local Anvil instance at a consistent address.

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Anvil and Forge available in your PATH
- `nc` (netcat) and `lsof` for checking and killing existing Anvil instances

## Deployment Script

The `deploy_anvil.sh` script:

1. Checks if Anvil is already running on port 8545 and kills it
2. Starts a fresh Anvil instance with a consistent mnemonic
3. Deploys the ZTNAPerimeterRegistry contract using the first account
4. Keeps Anvil running until manually stopped

## Usage

```bash
# Run the deployment script
./scripts/deploy_anvil.sh
```

## Configuration

The script uses the following configuration:

- Default mnemonic: `test test test test test test test test test test test junk`
- First account: `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`
- Private key: `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80` (DO NOT use in production)
- Contract address: `0x5FbDB2315678afecb367f032d93F642f64180aa3`

## Deterministic Addresses

The contract is deployed to a consistent address because:
1. We use a consistent mnemonic, which gives us the same accounts
2. We deploy as the first transaction from the first account, so the nonce is always 0
3. We kill any existing Anvil instance to ensure a fresh state

If you deploy additional contracts in the same Anvil session, they will have different addresses.

## Interacting with the Deployed Contract

Once deployed, you can interact with the contract using:

- Forge scripts
- Web3.js or ethers.js
- Hardhat console
- Any other Ethereum development tool that can connect to http://localhost:8545

## Stopping the Anvil Instance

Press `Ctrl+C` in the terminal where the script is running to stop the Anvil instance. 