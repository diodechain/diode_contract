#!/bin/bash
# Examples:
# ./scripts/update_oasis.sh 0xa51fBD85e1e4e1AC5ecd6b7DF5DB6993dA7030bb

export PROXY=0xf90314E31D34C7ad82382f1a9dCB5Fc0FDA71ACe
export RPC=https://sapphire.oasis.io

# export PROXY=0x18D1c56474505893082e1B50A7c5a7cdc7854Eca
# export RPC=https://testnet.sapphire.oasis.io

if [ -z "$1" ]; then
    echo "Usage: $0 <target>"
    exit 1
fi

set -e
set -x
cast send --legacy --rpc-url $RPC --private-key $(cat diode_glmr.key) $PROXY "SetContractInfo(address)" $1
