#!/bin/bash

# Examples:
# ./scripts/deploy_base.sh contracts/Bridge.sol:Bridge --constructor-args 0x3F3CD5038e4ebDf9dDA2332b89520Ae408424006 [] 3
# ./scripts/deploy_base.sh contracts/Proxy8.sol:Proxy8 --constructor-args 0x9B24EfcCBace6C485aC5E5F823D25EAFfB616A65 0x3F3CD5038e4ebDf9dDA2332b89520Ae408424006
# ./scripts/deploy_base.sh contracts/BNS.sol:BNS
# ./scripts/deploy_base.sh contracts/DiodeRegistryLight.sol:DiodeRegistryLight --constructor-args 0x3F3CD5038e4ebDf9dDA2332b89520Ae408424006 0x2bDC3e3441Dd5540eA50920C158405Ccd5727De2
# ./scripts/deploy_base.sh contracts/FleetContractUpgradeable.sol:FleetContractUpgradeable --constructor-args 0xfbfAF5BfF947869490C05d949c1BA5e260D6bd6E
# ./scripts/deploy_base.sh contracts/UpgradeLedger.sol:UpgradeLedger --constructor-args 0x7102533B13b950c964efd346Ee15041E3e55413f 0x2bDC3e3441Dd5540eA50920C158405Ccd5727De2
# ./scripts/deploy_base.sh contracts/Drive.sol:Drive --constructor-args 0x87C1D1304944a9EA16aF18CB777E3CeE0D3dACEa
# ./scripts/deploy_base.sh contracts/DriveMember.sol:DriveMember
# ./scripts/deploy_base.sh contracts/DriveFactory.sol:DriveFactory
# ./scripts/deploy_base.sh contracts/DriveInvites.sol:DriveInvites --constructor-args 0x1a36092d88fB73692eE7c502978D634C4AfCC486
# ./scripts/deploy_base.sh contracts/DevFleetContract.sol:DevFleetContract --constructor-args 0x3F3CD5038e4ebDf9dDA2332b89520Ae408424006
# ./scripts/deploy_base.sh contracts/DiodeNodeRegistry.sol:DiodeNodeRegistry --constructor-args 0x3F3CD5038e4ebDf9dDA2332b89520Ae408424006 0x2bDC3e3441Dd5540eA50920C158405Ccd5727De2

set -x
export RPC=https://developer-access-mainnet.base.org
export FOUNDRY_REMAPPINGS_DEV=cross=`pwd`/lib/base
forge create --broadcast --evm-version prague --optimize --optimizer-runs 200 --rpc-url $RPC --private-key $(cat diode_glmr.key) --delay 15 --verify --verifier=etherscan -e $(cat etherscan_api.key) $*

# forge verify-contract --evm-version prague --optimizer-runs 200 --rpc-url $RPC --delay 15 --verifier=etherscan -e $(cat etherscan_api.key) ...