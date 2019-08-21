const DiodeRegistry = artifacts.require("DiodeRegistry");
const FleetContract = artifacts.require("FleetContract");
const ERC20 = artifacts.require("ERC20");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(DiodeRegistry, accounts[0], { from: accounts[0], gasLimit: 200000000 }).then(function (instance) {
    deployer.deploy(FleetContract, instance.address, instance.address, accounts[0]);
  });
  deployer.deploy(ERC20, "Diode", "DD", 18, "10000000000000000000", { from: accounts[0] });
};
