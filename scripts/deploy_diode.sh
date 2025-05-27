#!/bin/bash
# Examples:
# ./scripts/deploy_diode.sh contracts/DriveMember.sol:DriveMember

set -x
export RPC=https://eu1.prenet.diode.io:8443
forge create --legacy --evm-version constantinople --optimize --optimizer-runs 200 --rpc-url $RPC --private-key $(cat diode_glmr.key) $*
