#!/usr/bin/env bash

node_modules/.bin/ganache-cli -p 9999 -l 1000000000 -g 100000000 > /dev/null &
ganachecli_pid=$!
echo "Start ganache-cli pid: $ganachecli_pid and sleep 3 seconds"

sleep 3

npm run test
ret=$?

kill -9 $ganachecli_pid
echo "Kill ganache-cli"

exit $ret