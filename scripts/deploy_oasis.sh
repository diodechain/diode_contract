#!/bin/bash
set -xe 
# Examples:
# ./scripts/deploy_oasis.sh contracts/Proxy8.sol:Proxy8 --constructor-args 0x58aaa43434e147F4EE076fae8804abA1bf1d802b 0xDA92764BB12E91010D132BcDd8e4a0270EE25fc9
# ./scripts/deploy_oasis.sh contracts/Proxy8.sol:Proxy8 --constructor-args 0x988C891e92678e06bf0e7F01c9327208EE294a5c 0x7102533B13b950c964efd346Ee15041E3e55413f
# ./scripts/deploy_oasis.sh contracts/ZTNAPerimeterRegistry.sol:ZTNAPerimeterRegistry

# ./scripts/deploy_oasis.sh contracts/MultiSigWallet.sol:MultiSigWallet --constructor-args ["0xA81c1450dd147cf99238072469C50d3b1b1f2C73","0xa432BaD7a40Be97875d5cba7822bBe47E6A5E1Dd","0x81dd8aFf2BcCc1002c4289C5bcBeF4110241A8E1","0x5420D71f9f78E6B50D555B6428BF3E154935880e","0x7102533B13b950c964efd346Ee15041E3e55413f"], 1
# ./scripts/deploy_oasis.sh contracts/DriveInvites.sol:DriveInvites --constructor-args 0x355DdBCf0e9fD70D78829eEcb443389290Ee53E1
# ./scripts/deploy_oasis.sh contracts/BNS.sol:BNS

# ./scripts/deploy_oasis.sh --use 0.7.6 --broadcast contracts/Drive.sol:Drive --constructor-args 0xBC7a66a80E760dD0D84f6e39Df6cfD937C6c94F6
# ./scripts/deploy_oasis.sh --use 0.7.6 --broadcast contracts/DriveMember.sol:DriveMember

export RPC=https://sapphire.oasis.io
# export RPC=https://testnet.sapphire.oasis.io

# Parse arguments to check if --use flag is already provided
has_use_flag=false
for arg in "$@"; do
  if [[ "$arg" == "--use" ]]; then
    has_use_flag=true
    break
  fi
done

# If --use flag is not provided, append the default version
if [ "$has_use_flag" = false ]; then
  ARGS="--use 0.8.24 $*"
else
  ARGS="$*"
fi


set -x
forge create --legacy --evm-version paris --optimize --optimizer-runs 200 --rpc-url $RPC --private-key $(cat diode_glmr.key) --verify --verifier sourcify $ARGS
