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
let clientAddr = ''

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
  if (env.CLIENT_ADDR !== undefined && Util.isValidAddress(env.CLIENT_ADDR)) {
    clientAddr = env.CLIENT_ADDR
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
    let txReceipt
    if (registryAddr === '') {
      ethTx.data = registryData
      ethTx.sign(privKey)
      txReceipt = await web3.eth.sendSignedTransaction(`0x${ethTx.serialize().toString('hex')}`)
        .on('transactionHash', (txHash) => {
          console.log('Deploy registry: ', txHash)
        })
      // await waitForMS(waitMS)
      tx.nonce += 1
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
        .on('transactionHash', (txHash) => {
          console.log('Deploy registry: ', txHash)
        })
      // await waitForMS(waitMS)
      tx.nonce += 1
      fleetAddr = txReceipt.contractAddress
      console.log('Fleet address: ', fleetAddr)
    }

    // set access whitelist
    if (deviceAddr !== '' && clientAddr !== '') {
      let batch = new web3.eth.BatchRequest();
      let methodData = '0x' + abi.methodID('SetAccessWhitelist', ['address', 'address', 'bool']).toString('hex') + abi.rawEncode(['address', 'address', 'bool'], [deviceAddr, clientAddr, true]).toString('hex')
      tx.to = fleetAddr
      tx.data = methodData
      ethTx = new EthereumTx(tx)
      ethTx.sign(privKey)
      req1 = web3.eth.sendSignedTransaction.request(`0x${ethTx.serialize().toString('hex')}`, (err, txHash) => {
        if (err) {
          console.warn(err)
          return
        }
        console.log('SetAccessWhitelist: ', txHash)
      })
      tx.nonce += 1

      // set device whitelist
      methodData = '0x' + abi.methodID('SetDeviceWhitelist', ['address', 'bool']).toString('hex') + abi.rawEncode(['address', 'bool'], [deviceAddr, true]).toString('hex')
      tx.to = fleetAddr
      tx.data = methodData
      ethTx = new EthereumTx(tx)
      ethTx.sign(privKey)
      req2 = web3.eth.sendSignedTransaction.request(`0x${ethTx.serialize().toString('hex')}`, (err, txHash) => {
        if (err) {
          console.warn(err)
          cb()
          return
        }
        console.log('SetDeviceWhitelist: ', txHash)
        cb()
      })
      batch.add(req1)
      batch.add(req2)
      // no Promise
      batch.execute()
      console.log('Set access whilist: ', deviceAddr)
      console.log('Set device whilist: ', deviceAddr)
    }
  } catch (err) {
    console.log(err)
    cb(err)
  }
}
