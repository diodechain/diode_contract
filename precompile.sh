#!/bin/bash
# Diode Contracts
# Copyright 2019 IoT Blockchain Technology Corporation LLC (IBTC)
# Licensed under the Diode License, Version 1.0
mkdir -p contracts/deps
for file in src/*.sol
do
  name=$(basename -- $file)
  sed -e 's:TEST_IF:TEST_IF\*/:g' -e 's:TEST_ELSE\*/:TEST_ELSE:g' src/$name > contracts/$name
done

for file in src/deps/*.sol
do
  name=$(basename -- $file)
  sed -e 's:TEST_IF:TEST_IF\*/:g' -e 's:TEST_ELSE\*/:TEST_ELSE:g' src/deps/$name > contracts/deps/$name
done

