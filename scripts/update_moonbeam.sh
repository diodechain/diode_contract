#!/bin/bash
# This script updates the target of the NodeRegistry contract proxy

# Examples:
# ./scripts/update_moonbeam.sh 0x8af6F5bfb5D02c6E084d787FB4338BaE9f9861E7

export PROXY=0xc4b466f63c0A31302Bc8A688A7c90e1199Bb6f84
export RPC=https://moonbeam.api.onfinality.io/rpc?apikey=7bf1dbfe-3539-4c1d-a3ba-5ad33a4b089a

if [ -z "$1" ]; then
    echo "Usage: $0 <target>"
    exit 1
fi

set -e
OLD_VSN=`cast call $PROXY "version()" --rpc-url $RPC | cast td`
if [ "$OLD_VSN" == "" ]; then
    echo "Failed to get current version"
    exit 1
fi
echo "Current version $OLD_VSN"

NEW_VSN=`cast call $1 "version()" --rpc-url $RPC | cast td`
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
