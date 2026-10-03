// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../../src/interface.sol";

contract Token is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialMint) ERC20(name, symbol) {
        _mint(msg.sender, initialMint);
    }
}

contract SashaBaseTest is Test {
    /// State Variable

    // Role
    address internal admin;
    address internal arbitrager;

    // Constant
    uint256 internal constant INIT_SUPPLY = 100 ether;

    // Router
    ISwapV2Router02 UniRouter = ISwapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    ISwapV2Router02 PankcakeRouter = ISwapV2Router02(0xEfF92A263d31888d860bD50809A8D171709b7b1c);

    // Token
    address internal LiaoToken;
    address internal DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    // Modifier
    modifier validation() {
        vm.startPrank(arbitrager);
        uint256 tokensBefore = ERC20(DAI).balanceOf(address(arbitrager));
        _;
        uint256 tokensAfter = ERC20(DAI).balanceOf(address(arbitrager));
        assertGt(tokensAfter, tokensBefore);
        vm.stopPrank();
    }

    /// Setup function
    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth", 20933505);

        admin = makeAddr("admin");
        arbitrager = makeAddr("arbitrager");

        vm.startPrank(admin);

        // Environment Configuration
        deal(DAI, admin, INIT_SUPPLY);

        LiaoToken = address(new Token("LiaoToken", "LT", INIT_SUPPLY));

        // // PancakeSwap Pool
        _addLiquidity(PankcakeRouter, LiaoToken, DAI, 10 ether, 20 ether);

        // Uniswap Pool
        _addLiquidity(UniRouter, LiaoToken, DAI, 10 ether, 10 ether);

        ERC20(DAI).transfer(arbitrager, 3 ether);

        vm.stopPrank();
    }

    function _addLiquidity(
        ISwapV2Router02 router,
        address token0,
        address token1,
        uint256 token0Amount,
        uint256 token1Amount
    ) internal {
        ERC20(token0).approve(address(router), type(uint256).max);
        ERC20(token1).approve(address(router), type(uint256).max);
        router.addLiquidity(
            token0, token1, token0Amount, token1Amount, token0Amount, token1Amount, admin, block.timestamp
        );
    }
}
