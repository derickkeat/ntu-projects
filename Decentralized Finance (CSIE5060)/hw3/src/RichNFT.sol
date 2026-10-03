// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RichNFT is ERC721 {
    IERC20 public weth; // Wrapped Ether token
    IERC20 public usdc; // USDC token

    uint256 public nextTokenId = 1;
    uint256 public constant WETH_THRESHOLD = 10000 * 1e18; // 10000 WETH
    uint256 public constant USDC_THRESHOLD = 10000 * 1e6; // 10000 USDC

    mapping(address => bool) isMinted;

    constructor(address _weth, address _usdc) ERC721("ExclusiveNFT", "ENFT") {
        weth = IERC20(_weth);
        usdc = IERC20(_usdc);
    }

    function mintRichNFT() external {
        require(isMinted[msg.sender] == false, "You are rich already");
        require(weth.balanceOf(msg.sender) >= WETH_THRESHOLD, "Insufficient WETH balance");
        require(usdc.balanceOf(msg.sender) >= USDC_THRESHOLD, "Insufficient USDC balance");

        uint256 tokenId = nextTokenId;

        isMinted[msg.sender] = true;

        weth.transfer(msg.sender, weth.balanceOf(address(this)));
        usdc.transfer(msg.sender, usdc.balanceOf(address(this)));

        _safeMint(msg.sender, tokenId);
        nextTokenId++;
    }
}
