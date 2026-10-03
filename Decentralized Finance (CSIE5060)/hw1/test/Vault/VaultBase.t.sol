// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {Test, console2} from "forge-std/Test.sol";

import {Vault} from "../../src/Vault/Vault.sol";

contract AssetToken is ERC20 {
    constructor() ERC20("AssetToken", "AT") {
        _mint(msg.sender, 100 ether);
    }
}

contract VaultBaseTest is Test {
    /// State Variable
    // Role
    address internal owner;
    address internal victim;
    address internal user;

    // Contract
    Vault internal vault;
    AssetToken internal token;

    // Modifier
    modifier validation() {
        vm.startPrank(user);
        _;
        vm.stopPrank();

        vm.startPrank(victim);
        uint256 amount = token.balanceOf(address(victim));
        token.approve(address(vault), amount);
        vault.deposit(amount, victim);
        vm.stopPrank();

        assertTrue(vault.balanceOf(address(victim)) == 0);
    }

    /// Setup function
    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");
        victim = makeAddr("victim");

        vm.prank(owner);
        token = new AssetToken();

        vm.prank(owner);
        token.transfer(user, 9 ether);

        vm.prank(owner);
        token.transfer(victim, 8 ether);

        vault = new Vault(token);
    }
}
