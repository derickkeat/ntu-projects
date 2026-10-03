// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Test, console2} from "forge-std/Test.sol";

import {BadProof} from "../../../src/Merkle/BadProof.sol";

contract BadProofBaseTest is Test {
    /// State Variable
    // Role
    address internal owner;
    address internal user0;
    address internal user1;
    address internal user2;
    address internal user3;
    address internal user4;
    address internal user5;
    address internal user6;
    address internal user7;

    // Contract
    BadProof internal token;

    // Modifier
    modifier validation() {
        uint256 balance;
        balance = token.balanceOf(address(this));
        assertEq(balance, 0);
        _;
        balance = token.balanceOf(address(this));
        assertEq(balance, 7);
    }

    /// Setup function
    function setUp() public {
        // Role
        owner = makeAddr("owner");
        user0 = makeAddr("user0"); // 0xfcffC2ac94d461b4C7A334DD1b7F7197f73e2a8f
        user1 = makeAddr("user1"); // 0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF
        user2 = makeAddr("user2"); // 0x537C8f3d3E18dF5517a58B3fB9D9143697996802
        user3 = makeAddr("user3"); // 0xc0A55e2205B289a967823662B841Bd67Aa362Aec
        user4 = makeAddr("user4"); // 0x90561e5Cd8025FA6F52d849e8867C14A77C94BA0
        user5 = makeAddr("user5"); // 0x22068447936722AcB3481F41eE8a0B7125526D55
        user6 = makeAddr("user6"); // 0xc1268511E6bC61c44C096f7F25B813Bd5531b64a
        user7 = address(this); // 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496

        bytes32 root = 0xbba65cdc0d237761fe5665f19c8cde005a82b284f0506b70a369ed00213d4e1a;
        token = new BadProof(root);

        // For user0
        bytes32[] memory proof = new bytes32[](3);
        proof[0] = 0x4e2ef3f4d279d23ce0933035d8c8fb3ce41acb03aa29a326c527a6c76b912f6e;
        proof[1] = 0x6597f70d724f82c27388bcf29e47213c310a3fbfc096c7b5e35cb260b509b204;
        proof[2] = 0xaf3fe72da8cb4bdad061724a6f9b418a211dfb4806159250d3bf89fdc8be0dc0;

        vm.prank(user0);
        token.mint(user0, proof);

        assertEq(token.balanceOf(user0), 1);
        assertEq(token.ownerOf(1), user0);
    }
}
