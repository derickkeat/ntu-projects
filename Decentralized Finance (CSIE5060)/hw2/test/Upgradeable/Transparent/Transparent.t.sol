// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Test, console2} from "forge-std/Test.sol";

import {TransparentBaseTest} from "./TransparentBase.t.sol";

interface IProxy {
    function upgradeTo(address _implementation) external;
    function proxyOwner() external returns (address);
    function implementation() external returns (address);
}

interface IBadName {
    function count() external view returns (uint256);
    function clash550254402() external;
    function upgradeTo() external;
}

interface IGoodName {
    function count() external view returns (uint256);
    function increment() external;
    function decrement() external;
}

contract TransparentTest is TransparentBaseTest {
    function testExploit() external validation {
        // Default Value //
        uint256 count;
        vm.prank(user);
        count = IBadName(address(proxy)).count();
        assertEq(count, 0);

        // BadName Proxy //
        vm.startPrank(user);
        IBadName(address(proxy)).clash550254402();
        count = IBadName(address(proxy)).count();
        assertEq(count, 1);

        IBadName(address(proxy)).upgradeTo();
        count = IBadName(address(proxy)).count();
        assertEq(count, 0);
        vm.stopPrank();

        // Upgrade Proxy //
        vm.startPrank(owner);
        address addr = IProxy(address(proxy)).proxyOwner();
        assertEq(addr, owner);

        IProxy(address(proxy)).upgradeTo(address(goodName));
        assertEq(IProxy(address(proxy)).implementation(), address(goodName));
        vm.stopPrank();

        // Default Value
        count = IBadName(address(proxy)).count();
        assertEq(count, 0);

        // GoodName Proxy
        vm.prank(user);
        IGoodName(address(proxy)).increment();
        count = IGoodName(address(proxy)).count();
        assertEq(count, 1);

        vm.prank(user);
        IGoodName(address(proxy)).decrement();
        count = IBadName(address(proxy)).count();
        assertEq(count, 0);
    }
}
