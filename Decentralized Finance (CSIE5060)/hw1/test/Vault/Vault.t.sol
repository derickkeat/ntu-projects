// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {Test, console2} from "forge-std/Test.sol";

import {VaultBaseTest} from "./VaultBase.t.sol";

contract VaultTest is VaultBaseTest {
    function testExploit() public validation {
        // TODO
        uint256 amount = token.balanceOf(address(user));
        token.approve(address(vault), amount);
        vault.deposit(1, user);

        token.transfer(address(vault), 8000000000000000000);
    }
}
