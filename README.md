# poc contract
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

# airswap ERC20 token to diode chain (diode)
Remember to change address and private key in `airswap.js` and set network properly.

```BASH
$truffle exec airswap.js --network ropsten
```
# diode testnet address
We run some diode nodes in different region. The address format of our diode nodes is [asia|europe|usa].testnet.diode.io. You can choose the nearest one and have fun with our node!

# setup device

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