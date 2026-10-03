// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {BadLenderBaseTest} from "./BadLenderBase.t.sol";

contract BadLenderTest is BadLenderBaseTest {
    function testExploit() external validation {
       // TODO
    }
}
