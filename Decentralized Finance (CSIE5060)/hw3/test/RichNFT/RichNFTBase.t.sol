// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {RichNFT} from "../../src/RichNFT.sol";

import "../../src/interface.sol";

contract RichNFTBaseTest is Test {
    /// State Variable
    // Role
    address internal admin;

    address internal pair = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;
    address internal usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC
    address internal weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH

    RichNFT internal nft;

    // Modifier
    modifier validation() {
        assertEq(nft.balanceOf(address(this)), 0);
        _;
        assertEq(nft.balanceOf(address(this)), 1);
    }

    /// Setup function
    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth", 20933505);
        admin = makeAddr("admin");

        deal(weth, admin, 40 * 1e18);
        deal(usdc, admin, 40 * 1e6);

        vm.startPrank(admin);
        nft = new RichNFT(weth, usdc);

        IERC20(weth).transfer(address(nft), 40 * 1e18);
        IERC20(usdc).transfer(address(nft), 40 * 1e6);

        vm.stopPrank();
    }
}
