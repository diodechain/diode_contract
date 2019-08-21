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
    else return web3.evm.mine().then(mineBlocks(number - 1))
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

  // hashTicket returns keccak256 hash of the ticket,
  function hashTicket (ticket) {
    let rawTicket = Object.keys(ticket).reduce(function (acc, now) {
      return acc + ticket[now];
    }, "");
    return ethUtil.keccak256(Buffer.from(rawTicket, 'hex'));
  }

  // newConnectionTicket returns a signed connection ticket
  function newConnectionTicket(blockHeight, fleetContract, nodeId, totalConnections, localAddress, devicePriv) {
    let connectionTicket = {
      blockHeight: ethUtil.toBuffer(blockHeight).toString('hex'),
      fleetContract: fleetContract.substr(2),
      nodeId: nodeId.substr(2),
      totalConnections: totalConnections.toString(),
      localAddress: localAddress.toString()
    };
    connectionTicket = formatTicket(connectionTicket);

    let ticketHash = hashTicket(connectionTicket);
    let sig = ethUtil.ecsign(ticketHash, devicePriv);
    let connectionTicketArr = [
      '0x' + connectionTicket.blockHeight,
      '0x' + connectionTicket.fleetContract,
      '0x' + connectionTicket.nodeId,
      '0x' + connectionTicket.totalConnections,
      '0x' + connectionTicket.localAddress,
      '0x' + sig.r.toString('hex').padStart(64, '0'),
      '0x' + sig.s.toString('hex').padStart(64, '0'),
      '0x' + ethUtil.toBuffer(sig.v).toString('hex').padStart(64, '0'),
    ];
    return connectionTicketArr;
  }

  // newTrafficTicket returns a signed traffic ticket
  function newTrafficTicket(blockHeight, fleetContract, nodeId, totalBytes, devicePriv, destinationId, clientPriv) {
    let trafficTicket = {
      blockHeight: ethUtil.toBuffer(blockHeight).toString('hex'),
      fleetContract: fleetContract.substr(2),
      nodeId: nodeId.substr(2),
      totalBytes: totalBytes,
      destinationId: destinationId.toString('hex'),
    };
    trafficTicket = formatTicket(trafficTicket);
    let rawTicket = Object.keys(trafficTicket).reduce(function (acc, now) {
      return acc + trafficTicket[now];
    }, "");
    let deviceTicketHash = ethUtil.keccak256(Buffer.from(rawTicket, 'hex'));
    let deviceSig = ethUtil.ecsign(deviceTicketHash, devicePriv);
    rawTicket += deviceSig.r.toString('hex').padStart(64, '0');
    rawTicket += deviceSig.s.toString('hex').padStart(64, '0');
    rawTicket += ethUtil.toBuffer(deviceSig.v).toString('hex').padStart(64, '0');
    let clientTicketHash = ethUtil.keccak256(Buffer.from(rawTicket, 'hex'));
    let clientSig = ethUtil.ecsign(clientTicketHash, clientPriv);
    let trafficTicketArr = [
      '0x' + trafficTicket.blockHeight,
      '0x' + trafficTicket.fleetContract,
      '0x' + trafficTicket.nodeId,
      '0x' + trafficTicket.totalBytes,
      '0x' + trafficTicket.destinationId,
      '0x' + deviceSig.r.toString('hex').padStart(64, '0'),
      '0x' + deviceSig.s.toString('hex').padStart(64, '0'),
      '0x' + ethUtil.toBuffer(deviceSig.v).toString('hex').padStart(64, '0'),
      '0x' + clientSig.r.toString('hex').padStart(64, '0'),
      '0x' + clientSig.s.toString('hex').padStart(64, '0'),
      '0x' + ethUtil.toBuffer(clientSig.v).toString('hex').padStart(64, '0'),
    ];
    return trafficTicketArr;
  }

  var stakeWaitingTime = 3;
  var unstakeWaitingTime = stakeWaitingTime;
  var redeemWaitingTime = stakeWaitingTime;
  var blockSeconds = 15;
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
    await registry.MinerStake({ from: secondAccount, value: 1e18 });
    await mineBlocks(stakeWaitingTime);
    stake = await registry.MinerValue(0, { from: secondAccount });
    assert.equal(stake.valueOf(), 1e18, "stake 1 ether");
    
    await registry.MinerStake({ from: secondAccount, value: 1e18 });
    await mineBlocks(stakeWaitingTime);
    stake = await registry.MinerValue(0, { from: secondAccount });
    assert.equal(stake.valueOf(), 2e18, "stake 2 ether");
    
    await registry.MinerStake({ from: secondAccount, value: 1e18 });
    stake = await registry.MinerValue(1, { from: secondAccount });
    assert.equal(stake.valueOf(), 1e18, "stake 1 ether (had not confirmed yet)");
  });

  it("should unstake 0.1 ether from miner", async () => {

    await mineBlocks(stakeWaitingTime);
    stake = await registry.MinerValue(0, { from: secondAccount });
    assert.equal(stake.valueOf(), 3e18, "stake 3 ether");

    await registry.MinerUnstake('100000000000000000', { from: secondAccount })
    await mineBlocks(unstakeWaitingTime);
    await registry.MinerWithdraw({ from: secondAccount });
    stake = await registry.MinerValue(0, { from: secondAccount });
    assert.equal(stake.valueOf(), 29e17, "stake 2.9 ether");

    stake = await registry.MinerValue(1, { from: secondAccount });
    assert.equal(stake.valueOf(), 0, "pending 0 ether");
  });

  it("should unstake 0.9 ether from miner", async () => {

    await registry.MinerUnstake('900000000000000000', { from: secondAccount })
    await mineBlocks(unstakeWaitingTime);
    await registry.MinerWithdraw({ from: secondAccount });
    stake = await registry.MinerValue(0, { from: secondAccount });
    assert.equal(stake.valueOf(), 2e18, "stake 2 ether");

    stake = await registry.MinerValue(1, { from: secondAccount });
    assert.equal(stake.valueOf(), 0, "stake 0 ether");
  });

  it("should delegate to create fleet contract for third account and stake 2 (1 + 1) ether", async () => {

    await registry.DelegateContractCreate(thirdAccount, { from: secondAccount, value: 1e18 });
    await mineBlocks(stakeWaitingTime);
    
    dfleetAddress = await registry.delegators(thirdAccount, { from: secondAccount });
    stake = await registry.ContractValue(0, dfleetAddress, { from: secondAccount });
    assert.equal(stake.valueOf(), 1e18, "stake 1 ether");

    dfleet = await FleetContract.at(dfleetAddress);
    let accountant = await dfleet.accountant();
    assert.equal(accountant, await registry.accountant());

    let operator = await dfleet.operator();
    assert.equal(operator, thirdAccount);

    await registry.ContractStake(thirdAccount, { from: secondAccount, value: 1e18 });
    stake = await registry.ContractValue(1, dfleetAddress, { from: secondAccount });
    assert.equal(stake.valueOf(), 1e18, "stake 1 ether");

    await mineBlocks(stakeWaitingTime);

    stake = await registry.ContractValue(0, dfleetAddress, { from: secondAccount });
    assert.equal(stake.valueOf(), 2e18, "stake 2 ether");
  });

  it("should delegate to unstake 2 ether", async () => {

    await registry.ContractUnstake(thirdAccount, '2000000000000000000', { from: secondAccount });
    await mineBlocks(unstakeWaitingTime);
    stake = await registry.ContractValue(0, dfleetAddress, { from: secondAccount });
    assert.equal(stake.valueOf(), 0, "stake 0 ether");

    let pendingStake = await registry.ContractValue(1, dfleetAddress, { from: secondAccount });
    assert.equal(pendingStake.valueOf(), 0, "pending stake 0 ether");

    let lockedStake = await registry.ContractValue(2, dfleetAddress, { from: secondAccount });
    assert.equal(lockedStake.valueOf(), 0, "locked stake 0 ether");

    claimableStake = await registry.ContractValue(3, dfleetAddress, { from: secondAccount });
    assert.equal(claimableStake.valueOf(), 2e18, "claimable stake 2 ether");
    
    await registry.ContractWithdraw(thirdAccount, { from: secondAccount });
    claimableStake = await registry.ContractValue(3, dfleetAddress, { from: secondAccount });
    assert.equal(claimableStake.valueOf(), 0, "claimable stake 0 ether");
  });

  it("should register a fleet contract and stake 2 (1 + 1) ether", async function() {
    fleet = await FleetContract.new(registry.address, firstAccount, secondAccount, { from: firstAccount })
    await registry.ContractStake(fleet.address, { from: secondAccount, value: 1e18 })
    await mineBlocks(stakeWaitingTime)
    stake = await registry.ContractValue(0, fleet.address)
    assert.equal(stake.valueOf(), 1e18, "stake 1 ether")

    await registry.ContractStake(fleet.address, { from: secondAccount, value: 1e18 })
    stake = await registry.ContractValue(1, fleet.address)
    assert.equal(stake.valueOf(), 1e18, "pending 1 ether")

    await mineBlocks(stakeWaitingTime)
    stake = await registry.ContractValue(1, fleet.address)
    assert.equal(stake.valueOf(), 0, "pending 0 ether")

    stake = await registry.ContractValue(0, fleet.address)
    assert.equal(stake.valueOf(), 2e18, "stake 2 ether")
  });

  it("should unstake 0.1 ether from fleet contract", async function() {
    await registry.ContractUnstake(fleet.address, '100000000000000000', { from: secondAccount })
    stake = await registry.ContractValue(2, fleet.address)
    assert.equal(stake.valueOf(), 1e17, "unstake pending 0.1 ether")

    await mineBlocks(unstakeWaitingTime)
    stake = await registry.ContractValue(3, fleet.address)
    assert.equal(stake.valueOf(), 1e17, "unstake 0.1 ether")

    await registry.ContractWithdraw(fleet.address, { from: secondAccount })
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
    await fleet.SetAccessWhitelist(`0x${firstDevice.addr.toString('hex')}`, true, { from: firstAccount });
    value = await fleet.accessWhitelist(`0x${firstDevice.addr.toString('hex')}`, { from: firstAccount });
    assert.equal(true, value);
  });

  it("should submit connection ticket for first device and second device, node should check the block height and signature", async function () {
    blockHeight = await web3.eth.getBlockNumber();
    // make connection ticket
    let connectionTicketArr = newConnectionTicket(blockHeight, fleet.address, secondAccount, '1', '0', firstDevice.priv);
    connectionTicketArr = connectionTicketArr.concat(newConnectionTicket(blockHeight, fleet.address, secondAccount, '1', '0', secondDevice.priv));
    let tx = await registry.SubmitConnectionTicketRaw(connectionTicketArr, { gas: 4000000 });
    let event = tx.logs[0];
    assert.equal(true, event !== undefined);
    assert.equal('Connection', event.event);
    assert.equal(`0x${firstDevice.addr.toString('hex').toLowerCase()}`, event.args.client.toLowerCase());

    event = tx.logs[1];
    assert.equal(true, event !== undefined);
    assert.equal('Connection', event.event);
    assert.equal(`0x${secondDevice.addr.toString('hex').toLowerCase()}`, event.args.client.toLowerCase());
  });

  it("should submit traffic ticket from first device and second device that go through second account (node) to first client (client)", async function () {
    let trafficTicketArr = newTrafficTicket(blockHeight, fleet.address, secondAccount, 'ff', firstDevice.priv, firstClient.addr, firstClient.priv);
    trafficTicketArr = trafficTicketArr.concat(newTrafficTicket(blockHeight, fleet.address, secondAccount, 'ff', secondDevice.priv, firstClient.addr, firstClient.priv));
    let tx = await registry.SubmitTrafficTicketRaw(trafficTicketArr, { gas: 4000000 });
    let event = tx.logs[0];
    assert.equal(true, event !== undefined);
    assert.equal('Traffic', event.event);
    assert.equal(`0x${firstDevice.addr.toString('hex').toLowerCase()}`, event.args.device.toLowerCase());
    assert.equal(`0x${firstClient.addr.toString('hex').toLowerCase()}`, event.args.client.toLowerCase());

    event = tx.logs[1];
    assert.equal(true, event !== undefined);
    assert.equal('Traffic', event.event);
    assert.equal(`0x${secondDevice.addr.toString('hex').toLowerCase()}`, event.args.device.toLowerCase());
    assert.equal(`0x${firstClient.addr.toString('hex').toLowerCase()}`, event.args.client.toLowerCase());
  });

  it("should redeem the ticket", async function () {
    let beforeStake = await registry.MinerValue(0, { from: secondAccount });
    let tx = await registry.blockReward();
    let event = tx.logs[0];
    assert.equal(true, event !== undefined);
    assert.equal('Rewards', event.event);
    assert.equal(secondAccount.toLowerCase(), event.args.node.toLowerCase());
    let afterStake = await registry.MinerValue(0, { from: secondAccount });
    assert.equal(event.args.amount.toString(), afterStake.sub(beforeStake).toString());
  });
});