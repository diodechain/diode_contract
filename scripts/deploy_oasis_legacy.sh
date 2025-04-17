#!/bin/bash

# Examples:
# ./scripts/deploy_oasis_legacy.sh contracts/MultiSigWallet.sol:MultiSigWallet --constructor-args ["0xA81c1450dd147cf99238072469C50d3b1b1f2C73","0xa432BaD7a40Be97875d5cba7822bBe47E6A5E1Dd","0x81dd8aFf2BcCc1002c4289C5bcBeF4110241A8E1","0x5420D71f9f78E6B50D555B6428BF3E154935880e","0x7102533B13b950c964efd346Ee15041E3e55413f"] 1
# ./scripts/deploy_oasis_legacy.sh contracts/BNS.sol:BNS

export RPC=https://sapphire.oasis.io
# export RPC=https://testnet.sapphire.oasis.io

set -x
forge create --legacy --evm-version paris --optimize --optimizer-runs 200 --rpc-url $RPC --private-key $(cat diode_glmr.key) $*
