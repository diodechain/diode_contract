pragma solidity 0.4.26;

/**
 * FleetContract
 *
 * TODO: emit event
 */
contract FleetContract {
  address private diodeRegistry;
  address /*payable*/ public operator;
  address public accountant;
  uint256 private value;
  bytes32 private accessRoot;
  bytes32 private deviceRoot;
  mapping(address => bool) public deviceWhitelist;
  mapping(address => bool) public accessWhitelist;

  modifier onlyOperator {
    require(msg.sender == operator);
    _;
  }

  constructor (address _diodeRegistry, address _operator, address _accountant) public {
    operator = _operator;
    diodeRegistry = _diodeRegistry;
    accountant = _accountant;
  }

  function SetDeviceWhitelist(address _client, bool _value) public onlyOperator {
    deviceWhitelist[_client] = _value;
  }

  function SetAccessWhitelist(address _client, bool _value) public onlyOperator {
    accessWhitelist[_client] = _value;
  }

  // function Value() public view returns (uint256) {
  //   return diodeRegistry.ContractValue(this);
  // }
}