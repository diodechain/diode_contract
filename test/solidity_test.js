// Diode Contracts
// Copyright 2021 Diode
// Licensed under the Diode License, Version 1.0
const path = require('path');
const fs = require('fs');

let items = fs.readdirSync("./test");
for (let i = 0; i < items.length; i++) {
    if (items[i].endsWith("_test.sol")) {
    // if (items[i].endsWith("Drive_test.sol")) {
        doTest(items[i]);
    }
}

function doTest(filename) {
    let name = path.basename(filename)
    // Cutting '_test.sol' and appending 'Test'
    // Eg. turning 'BNS_test.sol' into 'BNSTest' 
    let contractName = name.substr(0, name.length - 9) + 'Test';
    contractName = contractName.charAt(0).toUpperCase() + contractName.slice(1);
    
    let Contract = artifacts.require(contractName);
    let methods = [];
    Contract.abi.forEach(function (item) {
        if (item.type != "function") {
            return;
        }
        if (item.name.startsWith("check")) {
            methods.push(item)
        }
    });

    contract(contractName, async function (accounts) {
        let instance;
        it("initialize contract", async () => {
            instance = await Contract.new({ from: accounts[0], gasLimit: 4000000 });
        })

        methods.forEach(function (item) {
            let name = item.name;
            it(name, async () => {
                let idx = 0;
                // Changing calling account for name patterns such:
                // checkFrom1...
                // checkFrom2...
                // checkFrom3...
                for (let i = 0; i < accounts.length; i++) {
                    if (name.startsWith("checkFrom" + (i+1))) {
                        idx = i;
                        break;
                    }
                }
                let value = 0;
                if (item.stateMutability == 'payable') {
                    value = 100000;
                }
                await instance[name]({from: accounts[idx], value: value});
            })
        })
    });
}
