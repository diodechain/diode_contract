var ERC20 = artifacts.require("ERC20");

contract('ERC20', function(accounts) {
  var token;
  var firstAccount = accounts[0];
  var secondAccount = accounts[1];

  it("should mint 1 diode token to second account", function() {

    return ERC20.new("Diode", "dd", 18, "1000000000000000000000", { from: firstAccount, gasLimit: 4000000 }).then(function(instance) {
      token = instance;

      return token.mint(secondAccount, "1000000000000000000", { from: firstAccount, gasLimit: 4000000 });
    }).then(function () {
      return token.balanceOf(secondAccount);
    }).then(function (balance) {
      assert.equal(balance.valueOf(), "1000000000000000000", "mint 1 diode token");
    });
  });
});