#!/bin/bash
# Examples:
# ./scripts/update_oasis.sh 0xa51fBD85e1e4e1AC5ecd6b7DF5DB6993dA7030bb

export PROXY=0xBC7a66a80E760dD0D84f6e39Df6cfD937C6c94F6
export RPC=https://sapphire.oasis.io

# export PROXY=0x18D1c56474505893082e1B50A7c5a7cdc7854Eca
# export RPC=https://testnet.sapphire.oasis.io

if [ -z "$1" ]; then
    echo "Usage: $0 <target>"
    exit 1
fi

set -e
OLD_VSN=`cast call $PROXY "Version()" --rpc-url $RPC | cast td`
if [ "$OLD_VSN" == "" ]; then
    echo "Failed to get current version"
    exit 1
fi
echo "Current version $OLD_VSN"

NEW_VSN=`cast call $1 "Version()" --rpc-url $RPC | cast td`
if [ "$NEW_VSN" == "" ]; then
    echo "Failed to get new version"
    exit 1
fi
echo "New version $NEW_VSN"

OLD_HASH=$(cast keccak $(cast code $PROXY --rpc-url $RPC))
NEW_HASH=$(cast keccak $(cast code $1 --rpc-url $RPC))

if [ "$OLD_HASH" == "$NEW_HASH" ]; then
    echo "Code is the same, skipping"
    exit 0
fi

if [ "$OLD_VSN" == "$NEW_VSN" ]; then
    echo "Versions are the same but code is different, did you forget to update the version?"
    exit 1
fi

set -x
cast send --legacy --rpc-url $RPC --private-key $(cat diode_glmr.key) $PROXY "_proxy_set_target(address)" $1
