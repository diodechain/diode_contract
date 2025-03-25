// SPDX-License-Identifier: DIODE
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../contracts/ZTNAWallet.sol";

contract ZTNAWalletTest is Test {
    ZTNAWallet wallet;
    address testUser1;
    address testUser2;

    constructor() {
        // Set up test addresses
        testUser1 = address(0x1234);
        testUser2 = address(0x5678);
        wallet = new ZTNAWallet();
    }

    function testLogin() public {
        // Create a mock SiweAuth instance
        vm.chainId(0x5aff);
        SignatureRSV memory sig = SignatureRSV(
            0x159c01d0c61438117b96fc05561c76e9f640f6148741dd039a5ce2ee455638de,
            0x1f94c4e03f831507b231fa7e44ea59e42d165c8f3a3db092e319f01fae1187a2,
            27
        );

        string memory siwe = "ZTNAWallet wants you to sign in with your Ethereum account:\n"
            "0x040be01bc181fa0851ba2db5dd98f539cff5d8f7\n" "\n" "\n" "URI: http://ZTNAWallet\n" "Version: 1\n"
            "Chain ID: 23295\n" "Nonce: eb75d767-b412-4db1-b5ae-64eb2180d8b5\n" "Issued At: 2025-03-21T12:47:35.774Z";

        bytes memory eip191msg =
            abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(bytes(siwe).length), siwe);

        address addr = ecrecover(keccak256(eip191msg), uint8(sig.v), sig.r, sig.s);
        console2.log("addr", addr);

        AuthToken memory t = wallet.login_test(siwe, sig);
        console2.log("Domain", t.domain);
    }
}
