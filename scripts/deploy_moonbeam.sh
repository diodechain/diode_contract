#!/bin/bash

# Examples:
# ./scripts/deploy_moonbeam.sh src/Proxy.sol:Proxy --constructor-args 0x75637505b914eC9C6e9B8eDe383605cD117b0C99 0x3d565Ec28595c1a0710ABCBd8C0F979d31E38704
# ./scripts/deploy_moonbeam.sh src/DevFleetContract.sol:DevFleetContract --constructor-args 0x3d565Ec28595c1a0710ABCBd8C0F979d31E38704
# ./scripts/deploy_moonbeam.sh src/DriveMember.sol:DriveMember
# ./scripts/deploy_moonbeam.sh src/Drive.sol:Drive --constructor-args 0x8a093e3A83F63A00FFFC4729aa55482845a49294

set -x
export RPC=https://moonbeam.unitedbloc.com:3000
# export RPC=https://moonbeam.api.onfinality.io/rpc?apikey=7bf1dbfe-3539-4c1d-a3ba-5ad33a4b089a
forge create --rpc-url $RPC --private-key $(cat diode_glmr.key) --verify --verifier-url https://api-moonbeam.moonscan.io/api -e $(cat moonscan_api.key) $*
