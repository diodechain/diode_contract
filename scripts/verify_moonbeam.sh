#!/bin/bash

# Examples:
# ./scripts/verify_moonbeam.sh 0x2EE98b1Dcb555E38b33B9d73d258a2ffe5A4e577 src/DriveMember.sol:DriveMember
# ./scripts/verify_moonbeam.sh 0xC16f2C70c2c0B6EE436568f9faDd0ad5a8526e05 src/Drive.sol:Drive  --constructor-args $(cast abi-encode "constructor(address)" 0x8a093e3A83F63A00FFFC4729aa55482845a49294)



set -x
export RPC=https://moonbeam.unitedbloc.com:3000
# export RPC=https://moonbeam.api.onfinality.io/rpc?apikey=7bf1dbfe-3539-4c1d-a3ba-5ad33a4b089a
forge verify-contract --rpc-url $RPC --watch --verifier-url https://api-moonbeam.moonscan.io/api -e $(cat moonscan_api.key) --guess-constructor-args $*
