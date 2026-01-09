#!/bin/bash
# Examples:
# ./scripts/deploy_diode.sh contracts/DriveMember.sol:DriveMember
# ./scripts/deploy_diode.sh contracts/Drive.sol:Drive --constructor-args 0xaf60faa5cd840b724742f1af116168276112d6a6

set -x
export RPC=https://eu2.prenet.diode.io:8443
# export RPC=http://localhost:3834
forge create --legacy --evm-version constantinople --optimize --optimizer-runs 200 --rpc-url $RPC --private-key $(cat diode_glmr.key) $*
