# Diode Contracts
[![Build Status](https://travis-ci.com/diodechain/diode_contract.svg?branch=master)](https://travis-ci.com/diodechain/diode_contract)

Smart contract for diode chain. It also works on ethereum.

# development
1. start ganache-cli
```BASH
$npm run ganache
```

2. test
```BASH
$npm run test
```

2. build contracts
```BASH
$npm run build
```

# mint ERC20 tokens to test accounts
Remember to private key in `mintTokens.js` and set network properly.

```BASH
$truffle exec mintTokens.js --network ropsten
```

# Airswap ERC20 token to diode chain (diode)
Remember to change address and private key in `airswap.js` and set network properly.

```BASH
$truffle exec airswap.js --network ropsten
```
# Diode Testnet address
We run some diode nodes in different region. The primary addresses of the nodes are: testnet.diode.io . But you can also check https://diode.io/testnet/#/network for your nearest node.

# Diode Testnet foundation

The foundation contract is at 0x10000000000000000000 the owners are:

["0x3b9f7e8d713a83e627b915741b078944ab8a9f35", "0xb80dd8ff9d7c1c81cfa55f0f984b4a9f543a51c6", "0x2e13a61e2be33404976f7e04dd7e99f9ec1f0edf", "0xe5d636dbc4404312456b3f7f490fce0570f23104"]

# Setup device

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