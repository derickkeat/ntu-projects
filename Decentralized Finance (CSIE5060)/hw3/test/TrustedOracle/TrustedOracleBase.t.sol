// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {TrustedOracle, ChainlinkOracle} from "../../src/TrustedOracle.sol";

import "../../src/interface.sol";

contract TrustedOracleBaseTest is Test {
    /// State Variable
    address internal admin;

    TrustedOracle internal trustedOracle;

    ChainlinkOracle internal oracle0;
    ChainlinkOracle internal oracle1;
    ChainlinkOracle internal oracle2;

    /// Setup function
    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth", 20933505);
        admin = makeAddr("admin");

        vm.startPrank(admin);
        trustedOracle = new TrustedOracle();

        address priceFeed0 = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6; // USDC <> USD
        oracle0 = new ChainlinkOracle(priceFeed0);

        address priceFeed1 = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D; // USDT <> USD
        oracle1 = new ChainlinkOracle(priceFeed1);

        address priceFeed2 = 0xa569d910839Ae8865Da8F8e70FfFb0cBA869F961; // USDe <> USD
        oracle2 = new ChainlinkOracle(priceFeed2);

        trustedOracle.addOracle(address(oracle0));

        trustedOracle.addOracle(address(oracle1));

        trustedOracle.addOracle(address(oracle2));

        vm.stopPrank();
    }
}
