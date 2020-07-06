#!/bin/bash
# Diode Contracts
# Copyright 2019 IoT Blockchain Technology Corporation LLC (IBTC)
# Licensed under the Diode License, Version 1.0
for file in src/*
do
  name=$(basename -- $file)
  sed -e 's:TEST_IF:TEST_IF\*/:g' -e 's:TEST_ELSE\*/:TEST_ELSE:g' src/$name > contracts/$name
done
