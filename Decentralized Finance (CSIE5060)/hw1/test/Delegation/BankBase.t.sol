// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";

import {Bank} from "../../src/Delegation/Bank.sol";

contract BankBaseTest is Test {
    /// State Variable

    // Role
    address internal user;
    address internal victim;

    // Contract
    Bank internal bank;

    /// modifier
    modifier validation() {
        assertTrue(address(bank).balance == 100 ether);
        _;
        assertTrue(bank.balances(address(this)) == 100 ether);
    }

    /// Setup function
    function setUp() public {
        // Role
        victim = makeAddr("victim");
        deal(victim, 100 ether);

        deal(address(this), 1 ether);

        // Contract
        bank = new Bank();

        vm.prank(victim);
        bank.deposit{value: victim.balance}();
    }
}
