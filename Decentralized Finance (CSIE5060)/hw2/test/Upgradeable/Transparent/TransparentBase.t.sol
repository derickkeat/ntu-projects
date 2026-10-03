// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Test, console2} from "forge-std/Test.sol";

import {Proxy, BadName, GoodName} from "../../../src/Upgradeable/Transparent.sol";

contract TransparentBaseTest is Test {
    /// State Variable
    // Role
    address internal owner;
    address internal user;

    // Contract
    Proxy internal proxy;
    BadName internal badName;
    GoodName internal goodName;

    // Modifier
    modifier validation() {
        _;
    }

    /// Setup function
    function setUp() public {
        // Role
        owner = makeAddr("owner");
        user = makeAddr("user");

        vm.prank(owner);
        badName = new BadName();

        vm.prank(owner);
        goodName = new GoodName();

        vm.prank(owner);
        proxy = new Proxy(address(badName));
    }
}
