// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {TrustedOracleBaseTest} from "./TrustedOracleBase.t.sol";

import "../../src/interface.sol";

contract TrustedOracleTest is TrustedOracleBaseTest {
    function testExploit() public {
        uint256 price0 = oracle0.getPrice();

        assertEq(price0, 99995864);

        uint256 price1 = oracle1.getPrice();

        assertEq(price1, 99877361);

        uint256 price2 = oracle2.getPrice();

        assertEq(price2, 99847951);

        uint256 averagePrice = trustedOracle.getAveragePrice();

        assertEq(averagePrice, 99907058);
    }
}
