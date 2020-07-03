// Diode Contracts
// Copyright 2019 IoT Blockchain Technology Corporation LLC (IBTC)
// Licensed under the Diode License, Version 1.0
const BN = require("bn.js");
const crypto = require("crypto");
const ethUtil = require("ethereumjs-util");
var DiodeRegistry = artifacts.require("TestDiodeRegistry");
var FleetContract = artifacts.require("FleetContract");

contract('DiodeRegistry', async function(accounts) {

  web3.extend({
    property: 'evm',
    methods: [
      {
        name: 'mine',
        call: 'evm_mine',
        params: 1,
        inputFormatter: [null],
        outputFormatter: web3.utils.hexToNumberString,
      }
    ]
  });

  function mineBlocks(number) {
    if (number <= 1) return web3.evm.mine();
    else return web3.evm.mine().then(() => mineBlocks(number - 1))
  }

  // randPrivKey returns random length buffer data
  function randPrivKey(length) {
    let privKey = Buffer.alloc(length);
    crypto.randomFillSync(privKey);
    return privKey;
  }

  // account returns a object including priv, pub, addr
  function account() {
    let priv = randPrivKey(32);
    let pub = ethUtil.privateToPublic(priv);
    let addr = ethUtil.pubToAddress(pub);
    return {
      priv: priv,
      pub: pub,
      addr: addr,
    };
  }

  // formatTicket returns formated ticket
  function formatTicket (ticket) {
    Object.keys(ticket).forEach(function (key) {
      ticket[key] = ticket[key].padStart(64, '0');
    });
    return ticket;
  }

  function address(hex) {
    return hex.substring(hex.length-40).toLowerCase();
  }

  // hashTicket returns keccak256 hash of the ticket,
  function hashTicket (ticket) {
    let rawTicket = Object.keys(ticket).reduce(function (acc, now) {
      return acc + ticket[now];
    }, "");
    return ethUtil.keccak256(Buffer.from(rawTicket, 'hex'));
  }

  // newTicket returns a signed ticket
  async function newTicket(blockHeight, fleetContract, nodeId, totalConnections, totalBytes, localAddress, devicePriv) {
    let hash = (await web3.eth.getBlock(blockHeight)).hash
    let ticket = {
      blockHeight: hash.toString('hex').substr(2),
      fleetContract: fleetContract.substr(2),
      nodeId: nodeId.substr(2),
      totalConnections: totalConnections.toString(),
      totalBytes: totalBytes.toString(),
      localAddress: localAddress.toString()
    };
    ticket = formatTicket(ticket);
    let ticketHash = hashTicket(ticket);
    let sig = ethUtil.ecsign(ticketHash, devicePriv);
    let ticketArr = [
      '0x' + ethUtil.toBuffer(blockHeight).toString('hex').padStart(64, '0'),
      '0x' + ticket.fleetContract,
      '0x' + ticket.nodeId,
      '0x' + ticket.totalConnections,
      '0x' + ticket.totalBytes,
      '0x' + ticket.localAddress,
      '0x' + sig.r.toString('hex').padStart(64, '0'),
      '0x' + sig.s.toString('hex').padStart(64, '0'),
      '0x' + ethUtil.toBuffer(sig.v).toString('hex').padStart(64, '0'),
    ];
    return ticketArr;
  }

  function assertDiodeStackEvents(event, eventName, isContract, target, amount) {
    assert.equal(true, event !== undefined);
    assert.equal(eventName, event.event);
    assert.equal(isContract, event.args.isContract);
    assert.equal(target.toLowerCase(), event.args.target.toLowerCase());
    assert.equal(amount, event.args.amount);
  }

  var stakeWaitingTime = 3;
  var unstakeWaitingTime = stakeWaitingTime;
  var redeemWaitingTime = stakeWaitingTime;
  var blockSeconds = 15;
  var blocksPerEpoch = 4;
  var blockReward = new BN('1000000000000000000', 10);
  var minBlockReward = new BN('1000000000000000', 10);

  var redeemBlockHeight = redeemWaitingTime / blockSeconds;
  var redeemTargetBlockHeight;
  var blockHeight;
  var registry;
  var fleet;
  var stake;
  var dfleetAddress;
  var dfleet;
  var firstAccount = accounts[0];
  var secondAccount = accounts[1];
  var thirdAccount = accounts[2];
  var forthAccount = accounts[3];
  var firstDevice = account();
  var secondDevice = account();
  var firstClient = account();
  var msgHash = ethUtil.keccak256(Buffer.from("\u0019Ethereum Signed Message:\n0"));

  it("should register miner and stake 3 (2 + 1) ether", async () => {
    registry = await DiodeRegistry.new(secondAccount, { from: firstAccount, gasLimit: 10000000 });
    let tx = await registry.MinerStake({ from: secondAccount, value: 1e18 });
    let event = tx.logs[0];
    assertDiodeStackEvents(event, 'Staked', false, secondAccount, 1e18);
    await mineBlocks(stakeWaitingTime);
    stake = await registry.MinerValue(0, secondAccount);
    assert.equal(stake.valueOf(), 1e18, "stake 1 ether");

    tx = await registry.MinerStake({ from: secondAccount, value: 1e18 });
    event = tx.logs[0];
    assertDiodeStackEvents(event, 'Staked', false, secondAccount, 1e18);
    await mineBlocks(stakeWaitingTime);
    stake = await registry.MinerValue(0, secondAccount);
    assert.equal(stake.valueOf(), 2e18, "stake 2 ether");

    tx = await registry.MinerStake({ from: secondAccount, value: 1e18 });
    event = tx.logs[0];
    assertDiodeStackEvents(event, 'Staked', false, secondAccount, 1e18);
    stake = await registry.MinerValue(1, secondAccount);
    assert.equal(stake.valueOf(), 1e18, "stake 1 ether (had not confirmed yet)");
  });

  it("should unstake 0.1 ether from miner", async () => {

    await mineBlocks(stakeWaitingTime);
    stake = await registry.MinerValue(0, secondAccount);
    assert.equal(stake.valueOf(), 3e18, "stake 3 ether");

    let tx = await registry.MinerUnstake('100000000000000000', { from: secondAccount })
    let event = tx.logs[0];
    assertDiodeStackEvents(event, 'Unstaked', false, secondAccount, 1e17);
    await mineBlocks(unstakeWaitingTime);
    tx = await registry.MinerWithdraw({ from: secondAccount });
    event = tx.logs[0];
    assertDiodeStackEvents(event, 'Withdrawn', false, secondAccount, 1e17);
    stake = await registry.MinerValue(0, secondAccount);
    assert.equal(stake.valueOf(), 29e17, "stake 2.9 ether");

    stake = await registry.MinerValue(1, secondAccount);
    assert.equal(stake.valueOf(), 0, "pending 0 ether");
  });

  it("should unstake 0.9 ether from miner", async () => {

    let tx = await registry.MinerUnstake('900000000000000000', { from: secondAccount });
    let event = tx.logs[0];
    assertDiodeStackEvents(event, 'Unstaked', false, secondAccount, 9e17);
    await mineBlocks(unstakeWaitingTime);
    tx = await registry.MinerWithdraw({ from: secondAccount });
    event = tx.logs[0];
    assertDiodeStackEvents(event, 'Withdrawn', false, secondAccount, 9e17);
    stake = await registry.MinerValue(0, secondAccount);
    assert.equal(stake.valueOf(), 2e18, "stake 2 ether");

    stake = await registry.MinerValue(1, secondAccount);
    assert.equal(stake.valueOf(), 0, "stake 0 ether");
  });

  it("should register a fleet contract and stake 2 (1 + 1) ether", async function() {
    fleet = await FleetContract.new(registry.address, firstAccount, secondAccount, { from: firstAccount })
    let tx = await registry.ContractStake(fleet.address, { from: secondAccount, value: 1e18 })
    let event = tx.logs[0];
    assertDiodeStackEvents(event, 'Staked', true, fleet.address, 1e18);
    await mineBlocks(stakeWaitingTime)
    stake = await registry.ContractValue(0, fleet.address)
    assert.equal(stake.valueOf(), 1e18, "stake 1 ether")

    tx = await registry.ContractStake(fleet.address, { from: secondAccount, value: 1e18 })
    event = tx.logs[0];
    assertDiodeStackEvents(event, 'Staked', true, fleet.address, 1e18);
    stake = await registry.ContractValue(1, fleet.address)
    assert.equal(stake.valueOf(), 1e18, "pending 1 ether")

    await mineBlocks(stakeWaitingTime)
    stake = await registry.ContractValue(1, fleet.address)
    assert.equal(stake.valueOf(), 0, "pending 0 ether")

    stake = await registry.ContractValue(0, fleet.address)
    assert.equal(stake.valueOf(), 2e18, "stake 2 ether")
  });

  it("should unstake 0.1 ether from fleet contract", async function() {
    let tx = await registry.ContractUnstake(fleet.address, '100000000000000000', { from: secondAccount })
    let event = tx.logs[0];
    assertDiodeStackEvents(event, 'Unstaked', true, fleet.address, 1e17);
    stake = await registry.ContractValue(2, fleet.address)
    assert.equal(stake.valueOf(), 1e17, "unstake pending 0.1 ether")

    await mineBlocks(unstakeWaitingTime)
    stake = await registry.ContractValue(3, fleet.address)
    assert.equal(stake.valueOf(), 1e17, "unstake 0.1 ether")

    tx = await registry.ContractWithdraw(fleet.address, { from: secondAccount })
    event = tx.logs[0];
    assertDiodeStackEvents(event, 'Withdrawn', true, fleet.address, 1e17);
    stake = await registry.ContractValue(0, fleet.address)
    assert.equal(stake.valueOf(), 1.9e18, "stake 1 ether")
  });

  it("should set device whitelist", async function() {
    await fleet.SetDeviceWhitelist(`0x${firstDevice.addr.toString('hex')}`, true, { from: firstAccount });
    value = await fleet.deviceWhitelist(`0x${firstDevice.addr.toString('hex')}`, { from: firstAccount });
    assert.equal(true, value);

    await fleet.SetDeviceWhitelist(`0x${secondDevice.addr.toString('hex')}`, true, { from: firstAccount });
    value = await fleet.deviceWhitelist(`0x${secondDevice.addr.toString('hex')}`, { from: firstAccount });
    assert.equal(true, value);
  });

  it("should set access whitelist", async function() {
    await fleet.SetAccessWhitelist(`0x${firstDevice.addr.toString('hex')}`, firstAccount, true, { from: firstAccount });
    value = await fleet.accessWhitelist(`0x${firstDevice.addr.toString('hex')}`, firstAccount, { from: firstAccount });
    assert.equal(true, value);
  });

  it("should submit connection ticket for first device and second device, node should check the block height and signature", async function () {
    blockHeight = await web3.eth.getBlockNumber() - blocksPerEpoch;
    // make connection ticket
    let ticketArr = await newTicket(blockHeight, fleet.address, secondAccount, '1', '0', '0', firstDevice.priv);
    ticketArr = ticketArr.concat(await newTicket(blockHeight, fleet.address, secondAccount, '1', '0', '0', secondDevice.priv));
    let tx = await registry.SubmitTicketRaw(ticketArr, { gas: 4000000 });
    let event = tx.logs[0];
    assert.equal(true, event !== undefined);
    assert.equal('Ticket', event.event);
    assert.equal(`0x${firstDevice.addr.toString('hex').toLowerCase()}`, event.args.client.toLowerCase());

    event = tx.logs[1];
    assert.equal(true, event !== undefined);
    assert.equal('Ticket', event.event);
    assert.equal(`0x${secondDevice.addr.toString('hex').toLowerCase()}`, event.args.client.toLowerCase());
  });

  it("should submit traffic ticket from first device and second device that go through second account (node) to first client (client)", async function () {
    let trafficTicketArr = await newTicket(blockHeight, fleet.address, secondAccount, '0', 'ff', '0', firstDevice.priv);
    trafficTicketArr = trafficTicketArr.concat(await newTicket(blockHeight, fleet.address, secondAccount, '0', 'ff', '0', secondDevice.priv));
    let tx = await registry.SubmitTicketRaw(trafficTicketArr, { gas: 4000000 });
    let event = tx.logs[0];
    assert.equal(true, event !== undefined);
    assert.equal('Ticket', event.event);
    assert.equal(`0x${firstDevice.addr.toString('hex').toLowerCase()}`, event.args.client.toLowerCase());

    event = tx.logs[1];
    assert.equal(true, event !== undefined);
    assert.equal('Ticket', event.event);
    assert.equal(`0x${secondDevice.addr.toString('hex').toLowerCase()}`, event.args.client.toLowerCase());
  });

  it("should redeem the ticket", async function () {
    let beforeStake = await registry.MinerValue(0, secondAccount);
    let tx = await registry.blockReward({ from: secondAccount });
    let event = tx.logs[0];
    assert.equal(true, event !== undefined);
    assert.equal('Rewards', event.event);
    assert.equal(secondAccount.toLowerCase(), event.args.node.toLowerCase());
    let afterStake = await registry.MinerValue(0, secondAccount);
    assert.equal(event.args.amount.toString(), afterStake.sub(beforeStake).toString());
  });

  it("coinbase should earn blockreward", async function () {
    let coinbase = (await web3.eth.getBlock(blockHeight)).miner
    let beforeStake = await registry.MinerValue(0, coinbase);
    let tx = await registry.blockReward({ from: secondAccount });
    let afterStake = await registry.MinerValue(0, coinbase);

    let shouldDelta = beforeStake;
    if (beforeStake.cmp(blockReward) > 0) {
      shouldDelta = blockReward;
    } 
    let delta = afterStake.sub(beforeStake);

    assert.equal(beforeStake.add(shouldDelta).toString(), afterStake.toString());
    assert.equal(delta.toString(), shouldDelta.toString());
  });
});