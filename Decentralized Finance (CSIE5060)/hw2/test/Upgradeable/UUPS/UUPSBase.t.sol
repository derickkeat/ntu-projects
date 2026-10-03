// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Test, console2} from "forge-std/Test.sol";

import {Proxy, Logic, ILogic} from "../../../src/Upgradeable/UUPS.sol";

contract UUPSBaseTest is Test {
    /// State Variable
    // Role
    address internal owner;

    // Contract
    Proxy internal proxy;
    Logic internal logic;

    // Modifier
    modifier validation() {
        assertEq(address(logic).balance, 1 ether);
        _;
        assertEq(address(logic).balance, 0);
    }

    /// Setup function
    function setUp() public {
        // Role
        owner = makeAddr("owner");

        logic = new Logic();
        deal(address(logic), 1 ether);

        vm.prank(owner);
        proxy = new Proxy(address(logic));

        uint256 value;

        vm.startPrank(owner);

        ILogic(address(proxy)).increment();
        value = ILogic(address(proxy)).getNumber();
        assertEq(value, 1);

        ILogic(address(proxy)).increment();
        value = ILogic(address(proxy)).getNumber();
        assertEq(value, 2);

        ILogic(address(proxy)).decrement();
        value = ILogic(address(proxy)).getNumber();
        assertEq(value, 1);
        vm.stopPrank();
    }
}
