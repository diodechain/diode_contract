# Diode Contracts
![CI](https://github.com/diodechain/diode_contract/workflows/CI/badge.svg)
[![Build Status](https://travis-ci.com/diodechain/diode_contract.svg?branch=master)](https://travis-ci.com/diodechain/diode_contract)

Smart contracts for diode chain. Ethereum compatible. Can be tested with ganache and diode.

# Development

We're using node v12.16.1 (npm v6.14.7) and yarn for development. Best is to use nvm to select right version and get started

## Setup environment:



```BASH
$ nvm use
$ yarn
```

## Run tests:

```BASH
$ ./test.sh
```

## Build deployment contracts

```BASH
$ make clean && make
```

# Setup device (outdated)

Before connect to diodechain, you have to setup device to access/device whitelist.

ENV
```
REGISTRY_ADDR = Registry contract address
FLEET_ADDR = Fleet contract address
DEVICE_ADDR = Device address
CLIENT_ADDR = Client address
```

Example
```
$ REGISTRY_ADDR=0x5000000000000000000000000000000000000000  FLEET_ADDR=0x6000000000000000000000000000000000000000  DEVICE_ADDR=0x8f9dcc15a325581c81ca69f3889d444354312052 CLIENT_ADDR=0x6000000000000000000000000000000000000000 node_modules/.bin/truffle exec setupdevice.js
```
