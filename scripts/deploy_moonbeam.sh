#!/bin/bash

# Examples:
# ./scripts/deploy_moonbeam.sh contracts/BNS.sol:BNS
# ./scripts/deploy_moonbeam.sh contracts/DiodeToken.sol:DiodeToken --constructor-args 0x3d565Ec28595c1a0710ABCBd8C0F979d31E38704 0xA32a9eD71fBF22e6D197c13725Ad61958e9a4499 false
# ./scripts/deploy_moonbeam.sh contracts/DiodeRegistryLight.sol:DiodeRegistryLight --constructor-args 0x3d565Ec28595c1a0710ABCBd8C0F979d31E38704 0x434116a99619f2B465A137199C38c1Aab0353913
# ./scripts/deploy_moonbeam.sh contracts/Proxy.sol:Proxy --constructor-args 0x75637505b914eC9C6e9B8eDe383605cD117b0C99 0x3d565Ec28595c1a0710ABCBd8C0F979d31E38704
# ./scripts/deploy_moonbeam.sh contracts/DevFleetContract.sol:DevFleetContract --constructor-args 0x3d565Ec28595c1a0710ABCBd8C0F979d31E38704
# ./scripts/deploy_moonbeam.sh contracts/DriveMember.sol:DriveMember
# ./scripts/deploy_moonbeam.sh contracts/Drive.sol:Drive --constructor-args 0x8a093e3A83F63A00FFFC4729aa55482845a49294
# ./scripts/deploy_moonbeam.sh contracts/FleetContractUpgradeable.sol:FleetContractUpgradeable --constructor-args 0xD78653669fd3df4dF8F3141Ffa53462121d117a4
# ./scripts/deploy_moonbeam.sh contracts/Bridge.sol:Bridge --constructor-args 0x3d565Ec28595c1a0710ABCBd8C0F979d31E38704 [] 3


# BERRY TEST: ./scripts/deploy_moonbeam.sh contracts/YieldVault.sol:YieldVault --constructor-args 0xb9f1fa217c9a86915b4368e4ee9f079d6e5644a9 31536000 31536000 1500
# ./scripts/deploy_moonbeam.sh contracts/YieldVault.sol:YieldVault --constructor-args 0x434116a99619f2B465A137199C38c1Aab0353913 31536000 31536000 1500

set -x
# export RPC=https://moonbeam.unitedbloc.com:3000
export RPC=https://moonbeam.api.onfinality.io/rpc?apikey=7bf1dbfe-3539-4c1d-a3ba-5ad33a4b089a

# Cancun supported since RT3000 July 2024 https://forum.moonbeam.network/t/runtime-rt3000-schedule/1752/2
forge create --evm-version cancun --optimize --optimizer-runs 200 --rpc-url $RPC --private-key $(cat diode_glmr.key) --verify --verifier-url https://api-moonbeam.moonscan.io/api -e $(cat moonscan_api.key) $*
