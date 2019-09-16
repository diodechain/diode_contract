/**
 * Run this script to setup test environment
 * 1. deploy diode registry
 * 2. deploy test fleet contract
 * 3. stake diode into fleet contract
 */
const fs = require('fs')
const abi = require('ethereumjs-abi')
const Util = require('ethereumjs-util')
const DiodeRegistry = require("./build/contracts/TestDiodeRegistry.json")
const FleetContract = require("./build/contracts/FleetContract.json")
const key = fs.readFileSync("diode.secret").toString().trim();
const privKey = Buffer.from(key, 'hex')
const pubAddr = `0x${Util.privateToAddress(privKey).toString('hex')}`
const EthereumTx = require('ethereumjs-tx')
// 1s seconds each block
const waitMS = 1000

let registryConstructData = abi.rawEncode(["address"], [pubAddr]).toString("hex")
var registryData = DiodeRegistry.bytecode + registryConstructData
let registryAddr = ''
let fleetAddr = ''
let deviceAddr = ''

console.log("Accountant pubAddr: " + pubAddr)

function waitForMS(timeSleep) {
  return new Promise(function (resolve, reject) {
    setTimeout(function () {
      resolve()
    }, timeSleep)
  })
}

module.exports = async function (cb) {
  // process env
  let env = process.env
  if (env.REGISTRY_ADDR !== undefined && Util.isValidAddress(env.REGISTRY_ADDR)) {
    registryAddr = env.REGISTRY_ADDR
    console.log('Registry address: ', registryAddr)
  }
  if (env.FLEET_ADDR !== undefined && Util.isValidAddress(env.FLEET_ADDR)) {
    fleetAddr = env.FLEET_ADDR
    console.log('Fleet address: ', fleetAddr)
  }
  if (env.DEVICE_ADDR !== undefined && Util.isValidAddress(env.DEVICE_ADDR)) {
    deviceAddr = env.DEVICE_ADDR
  }
  let nonce = await web3.eth.getTransactionCount(pubAddr)
  // deploy diode registry
  let tx = {
    value: 0,
    gasPrice: 0,
    gasLimit: 6000000,
    data: '',
    nonce: nonce
  }
  try {
    let ethTx = new EthereumTx(tx)
    if (registryAddr === '') {
      ethTx.data = registryData
      ethTx.sign(privKey)
      let txReceipt = await web3.eth.sendSignedTransaction(`0x${ethTx.serialize().toString('hex')}`)
      tx.nonce += 1
      // await waitForMS(waitMS)
      registryAddr = txReceipt.contractAddress
      console.log('Registry address: ', registryAddr)
    }

    // deploy fleet contract
    if (fleetAddr === '') {
      let fleetConstructData = abi.rawEncode(["address", "address", "address"], [registryAddr, pubAddr, pubAddr]).toString("hex")
      let fleetData = FleetContract.bytecode + fleetConstructData;
      tx.data = fleetData
      ethTx = new EthereumTx(tx)
      ethTx.sign(privKey)
      txReceipt = await web3.eth.sendSignedTransaction(`0x${ethTx.serialize().toString('hex')}`)
      tx.nonce += 1
      // await waitForMS(waitMS)
      fleetAddr = txReceipt.contractAddress
      console.log('Fleet address: ', fleetAddr)
    }

    // set access whitelist
    if (deviceAddr !== '') {
      let methodData = '0x' + abi.methodID('SetAccessWhitelist', ['address', 'bool']).toString('hex') + abi.rawEncode(['address', 'bool'], [deviceAddr, true]).toString('hex')
      tx.to = fleetAddr
      tx.data = methodData
      ethTx = new EthereumTx(tx)
      ethTx.sign(privKey)
      txReceipt = await web3.eth.sendSignedTransaction(`0x${ethTx.serialize().toString('hex')}`)
      tx.nonce += 1
      // await waitForMS(waitMS)
      console.log('Set access whilist: ', deviceAddr)

      // set device whitelist
      methodData = '0x' + abi.methodID('SetDeviceWhitelist', ['address', 'bool']).toString('hex') + abi.rawEncode(['address', 'bool'], [deviceAddr, true]).toString('hex')
      tx.to = fleetAddr
      tx.data = methodData
      ethTx = new EthereumTx(tx)
      ethTx.sign(privKey)
      txReceipt = await web3.eth.sendSignedTransaction(`0x${ethTx.serialize().toString('hex')}`)
      // await waitForMS(waitMS)
      console.log('Set device whilist: ', deviceAddr)
    }
    cb()
  } catch (err) {
    console.log(err)
    cb(err)
  }
}
