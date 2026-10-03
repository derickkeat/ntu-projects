// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Test, console2} from "forge-std/Test.sol";

import {BadCaller} from "../../src/Loan/BadCaller.sol";

contract LoanToken is ERC20 {
    constructor() ERC20("LoanToken", "LT") {
        _mint(msg.sender, 100 ether);
    }
}

contract BadCallerBaseTest is Test {
    /// State Variable
    // Role
    address internal victim;
    address internal owner;

    // Contract
    BadCaller internal lender;
    LoanToken internal token;

    // Modifier
    modifier validation() {
        uint256 amount;
        amount = token.balanceOf(address(lender));
        assertTrue(amount == 100 ether);
        _;
        amount = token.balanceOf(address(lender));
        assertTrue(amount == 0);
    }

    /// Setup function
    function setUp() public {
        // Role
        victim = makeAddr("victim");
        owner = makeAddr("owner");

        // Contract
        vm.prank(owner);
        token = new LoanToken();

        vm.prank(owner);
        lender = new BadCaller(IERC20(token), 10020);

        uint256 amount = token.balanceOf(owner);

        vm.startPrank(owner);
        token.approve(address(lender), token.balanceOf(owner));
        lender.deposit(amount);
        vm.stopPrank();
    }
}
