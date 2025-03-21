#!/bin/bash

# Examples:
# ./scripts/deploy_oasis.sh contracts/Proxy8.sol:Proxy8 --constructor-args 0x988C891e92678e06bf0e7F01c9327208EE294a5c 0x7102533B13b950c964efd346Ee15041E3e55413f
# ./scripts/deploy_oasis.sh contracts/ZTNAPerimeterRegistry.sol:ZTNAPerimeterRegistry
export RPC=https://sapphire.oasis.io
export RPC=https://testnet.sapphire.oasis.io

set -x
forge create --legacy --evm-version berlin --optimize --optimizer-runs 200 --rpc-url $RPC --private-key $(cat diode_glmr.key) $*
