#!/bin/bash
set -e

# Check if Anvil is already running and kill it
if nc -z localhost 8545 2>/dev/null; then
  echo "Anvil is already running on port 8545. Stopping it..."
  # Find and kill the Anvil process
  ANVIL_PID=$(lsof -t -i:8545)
  if [ ! -z "$ANVIL_PID" ]; then
    kill $ANVIL_PID
    sleep 1
  fi
fi

# Start Anvil with a specific mnemonic to ensure consistent addresses
echo "Starting Anvil..."
anvil --chain-id 1337 --mnemonic "test test test test test test test test test test test junk" &
ANVIL_PID=$!

# Give Anvil some time to start
sleep 2

# Get the first account from Anvil (which is the default deployer)
echo "Getting default account from Anvil..."
DEFAULT_ACCOUNT=$(curl -s -X POST --data '{"jsonrpc":"2.0","method":"eth_accounts","params":[],"id":1}' -H "Content-Type: application/json" http://localhost:8545 | grep -o '"0x[a-fA-F0-9]*"' | head -1 | tr -d '"')
echo "Default account: $DEFAULT_ACCOUNT"

# Get the private key for the first account (this is the default private key for the first account with the test mnemonic)
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
echo "Using private key for default account"

# Deploy the ZTNAPerimeterRegistry contract
echo "Deploying ZTNAPerimeterRegistry contract..."
DEPLOYMENT_RESULT=$(forge create contracts/ZTNAPerimeterRegistry.sol:ZTNAPerimeterRegistry --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY --legacy)
echo "$DEPLOYMENT_RESULT"

# Extract the deployed contract address
DEPLOYED_ADDRESS=$(echo "$DEPLOYMENT_RESULT" | grep "Deployed to:" | awk '{print $3}')
echo "Contract deployed at: $DEPLOYED_ADDRESS"

# Keep Anvil running until user interrupts
echo "Anvil is running. Press Ctrl+C to stop..."
wait $ANVIL_PID 