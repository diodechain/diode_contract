#!/bin/bash
for file in DiodeStake DiodeRegistry
do
  sed -e 's:TEST_IF:TEST_IF\*/:g' -e 's:TEST_ELSE\*/:TEST_ELSE:g' contracts/$file.sol > contracts/Test$file.sol
done
