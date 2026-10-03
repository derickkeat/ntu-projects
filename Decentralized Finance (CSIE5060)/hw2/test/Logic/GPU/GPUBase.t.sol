// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Test, console2} from "forge-std/Test.sol";

import {GPUToken} from "../../../src/Logic/GPU.sol";

contract GPUBaseTest is Test {
    /// State Variable
    // Role
    address internal owner;

    // Contract
    GPUToken internal token;

    // Modifier
    modifier validation() {
        assertEq(token.balanceOf(address(this)), 1 ether);
        _;
        assertGt(token.balanceOf(address(this)), 10 ether);
    }

    /// Setup function
    function setUp() public {
        // Role
        owner = makeAddr("owner");

        vm.prank(owner);
        token = new GPUToken("GPU Token", "GPU");

        vm.prank(owner);
        token.mint(address(this), 1 ether);
    }
}
