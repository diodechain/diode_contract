// SPDX-License-Identifier: DIODE
pragma solidity >=0.7.6;

library Assert {
    event AssertionEvent(bool passed, string message);

    function ok(bool a, string memory message) internal pure returns (bool result) {
        result = a;
        require(result, message);
    }

    function notOk(bool a, string memory message) internal pure returns (bool result) {
        result = !a;
        ok(result, message);
    }

    function equal(uint256 a, uint256 b, string memory message) internal pure returns (bool result) {
        result = (a == b);
        ok(result, message);
    }

    function equal(int256 a, int256 b, string memory message) internal pure returns (bool result) {
        result = (a == b);
        ok(result, message);
    }

    function equal(bool a, bool b, string memory message) internal pure returns (bool result) {
        result = (a == b);
        ok(result, message);
    }

    function equal(address a, address b, string memory message) internal pure returns (bool result) {
        result = (a == b);
        ok(result, message);
    }

    function equal(bytes32 a, bytes32 b, string memory message) internal pure returns (bool result) {
        result = (a == b);
        ok(result, message);
    }

    function equal(string memory a, string memory b, string memory message) internal pure returns (bool result) {
        result = (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
        ok(result, message);
    }

    function notEqual(uint256 a, uint256 b, string memory message) internal pure returns (bool result) {
        result = (a != b);
        ok(result, message);
    }

    function notEqual(int256 a, int256 b, string memory message) internal pure returns (bool result) {
        result = (a != b);
        ok(result, message);
    }

    function notEqual(bool a, bool b, string memory message) internal pure returns (bool result) {
        result = (a != b);
        ok(result, message);
    }

    function notEqual(address a, address b, string memory message) internal pure returns (bool result) {
        result = (a != b);
        ok(result, message);
    }

    function notEqual(bytes32 a, bytes32 b, string memory message) internal pure returns (bool result) {
        result = (a != b);
        ok(result, message);
    }

    function notEqual(string memory a, string memory b, string memory message) internal pure returns (bool result) {
        result = (keccak256(abi.encodePacked(a)) != keccak256(abi.encodePacked(b)));
        ok(result, message);
    }
    /*----------------- Greater than --------------------*/

    function greaterThan(uint256 a, uint256 b, string memory message) internal pure returns (bool result) {
        result = (a > b);
        ok(result, message);
    }

    function greaterThan(int256 a, int256 b, string memory message) internal pure returns (bool result) {
        result = (a > b);
        ok(result, message);
    }
    // TODO: safely compare between uint and int

    function greaterThan(uint256 a, int256 b, string memory message) internal pure returns (bool result) {
        if (b < int256(0)) {
            // int is negative uint "a" always greater
            result = true;
        } else {
            result = (a > uint256(b));
        }
        ok(result, message);
    }

    function greaterThan(int256 a, uint256 b, string memory message) internal pure returns (bool result) {
        if (a < int256(0)) {
            // int is negative uint "b" always greater
            result = false;
        } else {
            result = (uint256(a) > b);
        }
        ok(result, message);
    }
    /*----------------- Lesser than --------------------*/

    function lesserThan(uint256 a, uint256 b, string memory message) internal pure returns (bool result) {
        result = (a < b);
        ok(result, message);
    }

    function lesserThan(int256 a, int256 b, string memory message) internal pure returns (bool result) {
        result = (a < b);
        ok(result, message);
    }
    // TODO: safely compare between uint and int

    function lesserThan(uint256 a, int256 b, string memory message) internal pure returns (bool result) {
        if (b < int256(0)) {
            // int is negative int "b" always lesser
            result = false;
        } else {
            result = (a < uint256(b));
        }
        ok(result, message);
    }

    function lesserThan(int256 a, uint256 b, string memory message) internal pure returns (bool result) {
        if (a < int256(0)) {
            // int is negative int "a" always lesser
            result = true;
        } else {
            result = (uint256(a) < b);
        }
        ok(result, message);
    }
}
