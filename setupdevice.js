/**
 * Run this script to setup test environment
 * 1. deploy diode registry
 * 2. deploy test fleet contract
 * 3. stake diode into fleet contract
 */
const fs = require('fs')
const abi = require('ethereumjs-abi')
const util = require('ethereumjs-util')
const DiodeRegistry = require("./build/contracts/TestDiodeRegistry.json")
const FleetContract = require("./build/contracts/FleetContract.json")
const key = fs.readFileSync("diode.secret").toString().trim();
const privKey = Buffer.from(key, 'hex')
const pubAddr = `0x${util.privateToAddress(privKey).toString('hex')}`
const EthereumTx = require('ethereumjs-tx')
// 1s seconds each block
const waitMS = 1000

let registryConstructData = abi.rawEncode(["address"], [pubAddr]).toString("hex")
var registryData = DiodeRegistry.bytecode + registryConstructData
let registryAddr = ''
let fleetAddr = ''
let deviceAddr = '0x8f9dcc15a325581c81ca69f3889d444354312052'

console.log("Accountant pubAddr: " + pubAddr)

function waitForMS(timeSleep) {
  return new Promise(function (resolve, reject) {
    setTimeout(function () {
      resolve()
    }, timeSleep)
  })
}
module.exports = async function () {
  let nonce = await web3.eth.getTransactionCount(pubAddr)
  // deploy diode registry
  let tx = {
    value: 0,
    gasPrice: 0,
    gasLimit: 6000000,
    data: registryData,
    nonce: nonce
  }
  try {
    let ethTx = new EthereumTx(tx)
    ethTx.sign(privKey)
    let txReceipt = await web3.eth.sendSignedTransaction(`0x${ethTx.serialize().toString('hex')}`)
    // await waitForMS(waitMS)
    registryAddr = txReceipt.contractAddress
    console.log('Registry address: ', registryAddr)

    // deploy fleet contract
    let fleetConstructData = abi.rawEncode(["address", "address", "address"], [registryAddr, pubAddr, pubAddr]).toString("hex")
    let fleetData = FleetContract.bytecode + fleetConstructData;
    tx.data = fleetData
    tx.nonce += 1
    ethTx = new EthereumTx(tx)
    ethTx.sign(privKey)
    txReceipt = await web3.eth.sendSignedTransaction(`0x${ethTx.serialize().toString('hex')}`)
    // await waitForMS(waitMS)
    fleetAddr = txReceipt.contractAddress
    console.log('Fleet address: ', fleetAddr)

    // set access whitelist
    let methodData = abi.methodID('SetAccessWhitelist', ['address', 'bool']).toString('hex') + abi.rawEncode(['address', 'bool'], [deviceAddr, true]).toString('hex')
    tx.data = methodData
    tx.nonce += 1
    ethTx = new EthereumTx(tx)
    ethTx.sign(privKey)
    txReceipt = await web3.eth.sendSignedTransaction(`0x${ethTx.serialize().toString('hex')}`)
    // await waitForMS(waitMS)
    console.log('Set access whilist: ', deviceAddr)

    // set device whitelist
    methodData = abi.methodID('SetDeviceWhitelist', ['address', 'bool']).toString('hex') + abi.rawEncode(['address', 'bool'], [deviceAddr, true]).toString('hex')
    tx.data = methodData
    tx.nonce += 1
    ethTx = new EthereumTx(tx)
    ethTx.sign(privKey)
    txReceipt = await web3.eth.sendSignedTransaction(`0x${ethTx.serialize().toString('hex')}`)
    // await waitForMS(waitMS)
    console.log('Set device whilist: ', deviceAddr)
    process.exit()
  } catch (err) {
    console.log(err)
    process.exit()
  }
}
