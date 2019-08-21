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