// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
let Create2Test = artifacts.require("Create2Test");

contract('Create2Test', async function (accounts) {

    let privateKey = "0x69ce0ceadb0cb471e1d75c93591ab95062d7381b5f8196dcd0dd576b31ee7c40";
    let account = web3.eth.accounts.privateKeyToAccount(privateKey);
    web3.eth.accounts.wallet.add(account);
    console.log("account = ", account.address)
    let code;

    it("should transfer funds to static address", async () => {
        let test = await Create2Test.new({ gasLimit: 10000000 });
        await test.transfer(account.address, { gasLimit: 10000000, value: 1000000000000000000 });
        code = test.constructor._json.bytecode;
    });

    it("should generate static address contract", async () => {
        assert.equal(1000000000000000000, await web3.eth.getBalance(account.address));

        let tx = await web3.eth.sendTransaction({
            from: account,
            data: code,
            gas: 4000000,
            nonce: 0
        });

        let address = tx.contractAddress;
        assert.equal(address, '0x23A126345Fce78f9A5aD2960ca62aB2080f902B0');

        let test2 = await Create2Test.at(address);

        await test2.executeCreate();
        let result2 = await test2.result();
        assert.equal(result2, "0x468f390402669E3dF953E180aF63F06d6fBEF8C5")

        await test2.executeCreate2();
        let result = await test2.result2();
        assert.equal(result, "0xC7Bb4F656CE3c9fC5bB6d0640066Cd747D6310B7")

        await test2.executeCreate2();
        result = await test2.result2();
        assert.equal(result, "0x0000000000000000000000000000000000000000")
    });
});