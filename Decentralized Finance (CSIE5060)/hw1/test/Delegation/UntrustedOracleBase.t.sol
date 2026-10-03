// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";

import {UntrustedOracle, OraclePriceStorage} from "../../src/Delegation/UntrustedOracle.sol";

// interface
interface IUntrustedOracle {
    function owner() external returns (address);
}

contract UntrustedOracleBaseTest is Test {
    /// State Variable

    // Role
    address internal owner;

    // Contract
    OraclePriceStorage internal oracleStorage0;
    OraclePriceStorage internal oracleStorage1;
    UntrustedOracle internal oracle;

    /// modifier
    modifier validation() {
        assertTrue(oracle.owner() == owner);
        _;
        assertTrue(oracle.owner() != owner);
    }

    /// Setup function
    function setUp() public {
        // Role
        owner = makeAddr("owner");

        // Contract
        oracleStorage0 = new OraclePriceStorage();
        oracleStorage1 = new OraclePriceStorage();

        vm.prank(owner);
        oracle = new UntrustedOracle(address(oracleStorage0), address(oracleStorage1));
    }
}
