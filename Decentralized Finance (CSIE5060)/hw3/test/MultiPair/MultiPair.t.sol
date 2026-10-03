// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {MultiPairBaseTest} from "./MultiPairBase.t.sol";

contract MultiPairTest is MultiPairBaseTest {
    function testExploit() external validation {
        ERC20(tokenA).approve(address(router), type(uint256).max);
        ERC20(tokenB).approve(address(router), type(uint256).max);
        ERC20(tokenC).approve(address(router), type(uint256).max);
        ERC20(tokenD).approve(address(router), type(uint256).max);
        ERC20(tokenE).approve(address(router), type(uint256).max);

        address[] memory path = new address[](2);
        path[0] = address(tokenB);
        path[1] = address(tokenA);
        router.swapExactTokensForTokens(
            3 ether,
            0,
            path,
            address(arbitrager),
            block.timestamp
        );

        uint256 ltBalance = IERC20(tokenA).balanceOf(address(arbitrager));
        address[] memory path2 = new address[](2);
        path2[0] = address(tokenA);
        path2[1] = address(tokenC);
        router.swapExactTokensForTokens(
            ltBalance,
            0,
            path2,
            address(arbitrager),
            block.timestamp
        );

        uint256 ltBalance2 = IERC20(tokenC).balanceOf(address(arbitrager));
        address[] memory path3 = new address[](2);
        path3[0] = address(tokenC);
        path3[1] = address(tokenE);
        router.swapExactTokensForTokens(
            ltBalance2,
            0,
            path3,
            address(arbitrager),
            block.timestamp
        );

        uint256 ltBalance3 = IERC20(tokenE).balanceOf(address(arbitrager));
        address[] memory path4 = new address[](2);
        path4[0] = address(tokenE);
        path4[1] = address(tokenD);
        router.swapExactTokensForTokens(
            ltBalance3,
            0,
            path4,
            address(arbitrager),
            block.timestamp
        );

        uint256 ltBalance4 = IERC20(tokenD).balanceOf(address(arbitrager));
        address[] memory path5 = new address[](2);
        path5[0] = address(tokenD);
        path5[1] = address(tokenC);
        router.swapExactTokensForTokens(
            ltBalance4,
            0,
            path5,
            address(arbitrager),
            block.timestamp
        );

        uint256 ltBalance5 = IERC20(tokenC).balanceOf(address(arbitrager));
        address[] memory path6 = new address[](2);
        path6[0] = address(tokenC);
        path6[1] = address(tokenB);
        router.swapExactTokensForTokens(
            ltBalance5,
            0,
            path6,
            address(arbitrager),
            block.timestamp
        );
    }
}
