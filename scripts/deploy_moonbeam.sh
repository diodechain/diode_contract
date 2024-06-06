#!/bin/bash

# Examples:
# ./scripts/deploy_moonbeam.sh src/DriveMember.sol:DriveMember
# ./scripts/deploy_moonbeam.sh src/Drive.sol:Drive --constructor-args 0x8a093e3A83F63A00FFFC4729aa55482845a49294

set -x
export RPC=https://moonbeam.unitedbloc.com:3000
# export RPC=https://moonbeam.api.onfinality.io/rpc?apikey=7bf1dbfe-3539-4c1d-a3ba-5ad33a4b089a
forge create --rpc-url $RPC --private-key $(cat diode_glmr.key) --verifier-url https://api-moonbeam.moonscan.io/api -e $(cat moonscan_api.key) $*
