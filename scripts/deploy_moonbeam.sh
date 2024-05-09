#!/bin/bash
set -x
export RPC=https://moonbeam.api.onfinality.io/rpc?apikey=7bf1dbfe-3539-4c1d-a3ba-5ad33a4b089a

forge create --rpc-url $RPC --private-key $(cat diode_glmr.key) --verifier-url https://api-moonbeam.moonscan.io/api -e $(cat moonscan_api.key) $*