// SPDX-License-Identifier: DIODE
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./Assert.sol";
import "./CallForwarder.sol";
import "../contracts/UpgradeLedger.sol";

// Mock ERC20 token for testing
contract MockERC20 {
    string public name = "Mock Token";
    string public symbol = "MOCK";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function mint(address to, uint256 value) public {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }
}

contract UpgradeLedgerTest {
    UpgradeLedger ledger;
    MockERC20 token;
    CallForwarder user1;
    CallForwarder user2;
    address owner;

    constructor() {
        owner = address(this);
        token = new MockERC20(1000000 ether); // 1M tokens
        ledger = new UpgradeLedger(owner, address(token));

        // Create test users
        user1 = new CallForwarder(address(ledger));
        user2 = new CallForwarder(address(ledger));

        // Give tokens to users
        token.mint(address(user1), 1000 ether);
        token.mint(address(user2), 1000 ether);
    }

    function testConstructor() public {
        // Test that TOKEN is set correctly
        Assert.equal(address(ledger.TOKEN()), address(token), "TOKEN should be set correctly");

        // Test that owner is set correctly
        Assert.equal(ledger.owner(), payable(owner), "Owner should be set correctly");
    }

    function testRecordPayment() public {
        uint256 amount = 100 ether;
        string memory reason = "Test payment";

        // User1 approves ledger to spend tokens
        user1.__updateTarget(address(token));
        address(user1).call(abi.encodeWithSignature("approve(address,uint256)", address(ledger), amount));
        user1.__updateTarget(address(ledger));

        // Check initial balances
        uint256 initialContractBalance = token.balanceOf(address(ledger));
        uint256 initialUser1Balance = token.balanceOf(address(user1));

        // Record payment
        address(user1).call(abi.encodeWithSignature("RecordPayment(uint256,string)", amount, reason));

        // Check balances after payment
        Assert.equal(
            token.balanceOf(address(ledger)), initialContractBalance + amount, "Contract should receive tokens"
        );
        Assert.equal(token.balanceOf(address(user1)), initialUser1Balance - amount, "User should lose tokens");

        // Check payment record
        UpgradeLedger.Payment[] memory payments = ledger.GetPayments(address(user1));
        Assert.equal(payments.length, 1, "Should have 1 payment");
        Assert.equal(payments[0].sender, address(user1), "Sender should be correct");
        Assert.equal(payments[0].amount, amount, "Amount should be correct");
        Assert.equal(payments[0].reason, reason, "Reason should be correct");
        Assert.notEqual(payments[0].timestamp, 0, "Timestamp should be set");
    }

    function testRecordPaymentZeroAmount() public {
        // Try to record payment with zero amount
        (bool success,) = address(user1).call(abi.encodeWithSignature("RecordPayment(uint256,string)", 0, "Test"));

        // Should fail
        Assert.notOk(success, "Zero amount payment should fail");
    }

    function testRecordPaymentInsufficientAllowance() public {
        uint256 amount = 100 ether;

        // User1 doesn't approve enough tokens
        user1.__updateTarget(address(token));
        address(user1).call(abi.encodeWithSignature("approve(address,uint256)", address(ledger), amount - 1));
        user1.__updateTarget(address(ledger));

        // Try to record payment
        (bool success,) = address(user1).call(abi.encodeWithSignature("RecordPayment(uint256,string)", amount, "Test"));

        // Should fail due to insufficient allowance
        Assert.notOk(success, "Payment with insufficient allowance should fail");
    }

    function testMultiplePayments() public {
        uint256 amount1 = 50 ether;
        uint256 amount2 = 75 ether;
        string memory reason1 = "First payment";
        string memory reason2 = "Second payment";

        // Approve tokens
        user1.__updateTarget(address(token));
        address(user1).call(abi.encodeWithSignature("approve(address,uint256)", address(ledger), amount1 + amount2));
        user1.__updateTarget(address(ledger));

        // Record first payment
        address(user1).call(abi.encodeWithSignature("RecordPayment(uint256,string)", amount1, reason1));

        // Record second payment
        address(user1).call(abi.encodeWithSignature("RecordPayment(uint256,string)", amount2, reason2));

        // Check payments
        UpgradeLedger.Payment[] memory payments = ledger.GetPayments(address(user1));
        Assert.equal(payments.length, 2, "Should have 2 payments");

        Assert.equal(payments[0].amount, amount1, "First payment amount should be correct");
        Assert.equal(payments[0].reason, reason1, "First payment reason should be correct");

        Assert.equal(payments[1].amount, amount2, "Second payment amount should be correct");
        Assert.equal(payments[1].reason, reason2, "Second payment reason should be correct");
    }

    function testGetPaymentsForDifferentUsers() public {
        uint256 amount1 = 25 ether;
        uint256 amount2 = 35 ether;

        // User1 approves and pays
        user1.__updateTarget(address(token));
        address(user1).call(abi.encodeWithSignature("approve(address,uint256)", address(ledger), amount1));
        user1.__updateTarget(address(ledger));
        address(user1).call(abi.encodeWithSignature("RecordPayment(uint256,string)", amount1, "User1 payment"));

        // User2 approves and pays
        user2.__updateTarget(address(token));
        address(user2).call(abi.encodeWithSignature("approve(address,uint256)", address(ledger), amount2));
        user2.__updateTarget(address(ledger));
        address(user2).call(abi.encodeWithSignature("RecordPayment(uint256,string)", amount2, "User2 payment"));

        // Check user1 payments
        UpgradeLedger.Payment[] memory user1Payments = ledger.GetPayments(address(user1));
        Assert.equal(user1Payments.length, 1, "User1 should have 1 payment");
        Assert.equal(user1Payments[0].amount, amount1, "User1 payment amount should be correct");

        // Check user2 payments
        UpgradeLedger.Payment[] memory user2Payments = ledger.GetPayments(address(user2));
        Assert.equal(user2Payments.length, 1, "User2 should have 1 payment");
        Assert.equal(user2Payments[0].amount, amount2, "User2 payment amount should be correct");

        // Check empty address
        UpgradeLedger.Payment[] memory emptyPayments = ledger.GetPayments(address(0));
        Assert.equal(emptyPayments.length, 0, "Empty address should have no payments");
    }

    function testWithdraw() public {
        uint256 paymentAmount = 200 ether;
        uint256 withdrawAmount = 100 ether;

        // Record payment to have tokens in contract
        user1.__updateTarget(address(token));
        address(user1).call(abi.encodeWithSignature("approve(address,uint256)", address(ledger), paymentAmount));
        user1.__updateTarget(address(ledger));
        address(user1)
            .call(abi.encodeWithSignature("RecordPayment(uint256,string)", paymentAmount, "Payment for withdrawal"));

        // Check initial balances
        uint256 initialContractBalance = token.balanceOf(address(ledger));
        uint256 initialOwnerBalance = token.balanceOf(owner);

        // Withdraw as owner
        ledger.Withdraw(withdrawAmount, owner);

        // Check balances after withdrawal
        Assert.equal(
            token.balanceOf(address(ledger)),
            initialContractBalance - withdrawAmount,
            "Contract balance should decrease"
        );
        Assert.equal(token.balanceOf(owner), initialOwnerBalance + withdrawAmount, "Owner should receive tokens");
    }

    function testWithdrawZeroAmount() public {
        // Try to withdraw zero amount
        (bool success,) = address(this).call(abi.encodeWithSignature("Withdraw(uint256,address)", 0, owner));

        // Should fail
        Assert.notOk(success, "Zero amount withdrawal should fail");
    }

    function testWithdrawToZeroAddress() public {
        // Record payment first
        user1.__updateTarget(address(token));
        address(user1).call(abi.encodeWithSignature("approve(address,uint256)", address(ledger), 100 ether));
        user1.__updateTarget(address(ledger));
        address(user1).call(abi.encodeWithSignature("RecordPayment(uint256,string)", 100 ether, "Payment"));

        // Try to withdraw to zero address
        (bool success,) = address(this).call(abi.encodeWithSignature("Withdraw(uint256,address)", 50 ether, address(0)));

        // Should fail
        Assert.notOk(success, "Withdrawal to zero address should fail");
    }

    function testWithdrawNotOwner() public {
        // Record payment first
        user1.__updateTarget(address(token));
        address(user1).call(abi.encodeWithSignature("approve(address,uint256)", address(ledger), 100 ether));
        user1.__updateTarget(address(ledger));
        address(user1).call(abi.encodeWithSignature("RecordPayment(uint256,string)", 100 ether, "Payment"));

        // Try to withdraw as non-owner
        (bool success,) =
            address(user1).call(abi.encodeWithSignature("Withdraw(uint256,address)", 50 ether, address(user1)));

        // Should fail
        Assert.notOk(success, "Non-owner withdrawal should fail");
    }

    function testChangeTracker() public {
        uint256 initialChange = ledger.change_tracker();

        // Record payment to trigger change tracker update
        user1.__updateTarget(address(token));
        address(user1).call(abi.encodeWithSignature("approve(address,uint256)", address(ledger), 50 ether));
        user1.__updateTarget(address(ledger));
        address(user1).call(abi.encodeWithSignature("RecordPayment(uint256,string)", 50 ether, "Payment"));

        // Change tracker should be updated
        Assert.notEqual(ledger.change_tracker(), initialChange, "Change tracker should be updated after payment");
    }
}
