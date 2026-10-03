// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Test, console2} from "forge-std/Test.sol";

import {MultisigBaseTest} from "./MultisigBase.t.sol";

contract MultisigTest is MultisigBaseTest {
    function testExploit() external validation {}
}
