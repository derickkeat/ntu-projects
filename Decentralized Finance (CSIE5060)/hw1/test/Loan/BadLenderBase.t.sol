// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {BadLender} from "../../src/Loan/BadLender.sol";

contract BadLenderBaseTest is Test {
    /// State Variable
    // Role
    address internal victim;

    // Contract
    BadLender internal lender;

    /// Modifier
    modifier validation() {
        assertTrue(address(this).balance == 0);
        _;
        assertTrue(address(this).balance > 0);
    }

    /// Setup function
    function setUp() public {
        lender = new BadLender();

        victim = makeAddr("victim");
        deal(victim, 100 ether);
        deal(address(this), 0);

        vm.prank(victim);
        lender.deposit{value: victim.balance}();
    }
}
