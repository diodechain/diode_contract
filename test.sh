#!/usr/bin/env bash
# Diode Contracts
# Copyright 2019 IoT Blockchain Technology Corporation LLC (IBTC)
# Licensed under the Diode License, Version 1.0
node_modules/.bin/ganache-cli -p 8545 -l 1000000000 -g 100000000 > /dev/null &
ganachecli_pid=$!
echo "Start ganache-cli pid: $ganachecli_pid and sleep 3 seconds"

sleep 3

make test
ret=$?

kill -9 $ganachecli_pid
echo "Kill ganache-cli"

exit $ret
