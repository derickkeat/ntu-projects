// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Test, console2} from "forge-std/Test.sol";

import {BadLeaf} from "../../../src/Merkle/BadLeaf.sol";

contract BadLeafBaseTest is Test {
    /// State Variable
    // Role
    address internal owner;
    address internal user0;
    address internal user1;
    address internal user2;
    address internal user3;

    // Contract
    BadLeaf internal token;

    // Modifier
    modifier validation() {
        uint256 balance;
        balance = token.balanceOf(address(this));
        assertEq(balance, 0);
        _;
        balance = token.balanceOf(address(this));
        assertEq(balance, 2);
    }

    /// Setup function
    function setUp() public {
        // Role
        owner = makeAddr("owner");
        user0 = makeAddr("user0"); // 0xfcffC2ac94d461b4C7A334DD1b7F7197f73e2a8f
        user1 = makeAddr("user1"); // 0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF
        user2 = makeAddr("user2"); // 0x537C8f3d3E18dF5517a58B3fB9D9143697996802
        user3 = makeAddr("user3"); // 0xc0A55e2205B289a967823662B841Bd67Aa362Aec

        bytes32 root = 0x650de55dfddd8a78ca083dbae3094bef74d3f52a69342e5e16b18b93ef8977cf;
        vm.prank(owner);
        token = new BadLeaf(root);

        bytes32 leaf = token.getLeafNode(user0, 5); // Lucky Number for user0 is 5!
        bytes32[] memory proof = new bytes32[](2);

        proof[0] = 0x592381370dc817a5abc6f2dad6b068f1652cdc40a0c2400ed9d9e1e717c00913;
        proof[1] = 0x1ac64a5f9dce300ae9bb07d1b64083f34e0bc6717ef1663ca7f656fb9ed83bb9;

        vm.prank(user0);
        token.verify(proof, leaf);

        address tokenOwner = token.ownerOf(1);
        assertEq(tokenOwner, user0);
    }
}
