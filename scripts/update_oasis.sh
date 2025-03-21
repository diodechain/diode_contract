#!/bin/bash
# Examples:
# ./scripts/update_oasis.sh 0xa51fBD85e1e4e1AC5ecd6b7DF5DB6993dA7030bb

export RPC=https://sapphire.oasis.io
export PROXY=0x18D1c56474505893082e1B50A7c5a7cdc7854Eca
export RPC=https://testnet.sapphire.oasis.io

if [ -z "$1" ]; then
    echo "Usage: $0 <target>"
    exit 1
fi

set -e
OLD_VSN=`cast call $PROXY "Version()" --rpc-url $RPC | cast td`
echo "Current version $OLD_VSN"
NEW_VSN=`cast call $1 "Version()" --rpc-url $RPC | cast td`
echo "Deploying new version $NEW_VSN"

if [ "$OLD_VSN" == "$NEW_VSN" ]; then
    echo "Versions are the same, skipping"
    exit 0
fi

set -x
cast send --legacy --rpc-url $RPC --private-key $(cat diode_glmr.key) $PROXY "_proxy_set_target(address)" $1
