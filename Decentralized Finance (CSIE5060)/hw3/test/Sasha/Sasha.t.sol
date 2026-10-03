// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {SashaBaseTest} from "./SashaBase.t.sol";

import "../../src/interface.sol";

contract SashaTest is SashaBaseTest {
    function testExploit() public validation {
        ERC20(DAI).approve(address(UniRouter), type(uint256).max);
        ERC20(LiaoToken).approve(address(PankcakeRouter), type(uint256).max);

        address[] memory pathUni = new address[](2);
        pathUni[0] = DAI;
        pathUni[1] = LiaoToken;
        UniRouter.swapExactTokensForTokens(
            3 ether,
            0,
            pathUni,
            address(arbitrager),
            block.timestamp
        );

        uint256 ltBalance = ERC20(LiaoToken).balanceOf(address(arbitrager));
        address[] memory pathPan = new address[](2);
        pathPan[0] = LiaoToken;
        pathPan[1] = DAI;
        PankcakeRouter.swapExactTokensForTokens(
            ltBalance,
            3 ether,
            pathPan,
            address(arbitrager),
            block.timestamp
        );

    }
}
