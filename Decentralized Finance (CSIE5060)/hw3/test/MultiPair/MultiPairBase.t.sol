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

contract MultiPairBaseTest is Test {
    /// State Variable
    // Role
    address internal admin;
    address internal arbitrager;

    // Constant
    uint256 internal constant INIT_SUPPLY = 100 ether;
    ISwapV2Router02 router = ISwapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    // Token
    Token tokenA;
    Token tokenB;
    Token tokenC;
    Token tokenD;
    Token tokenE;

    // Modifier
    modifier validation() {
        vm.startPrank(arbitrager);
        uint256 tokensBefore = tokenB.balanceOf(arbitrager);
        _;
        uint256 tokensAfter = tokenB.balanceOf(arbitrager);
        assertGt(tokensAfter, 22 ether);
        vm.stopPrank();
    }

    /// Setup function
    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth", 20933505);
        admin = makeAddr("admin");
        arbitrager = makeAddr("arbitrager");

        vm.startPrank(admin);

        tokenA = new Token("tokenA", "A", INIT_SUPPLY);
        tokenB = new Token("tokenB", "B", INIT_SUPPLY);
        tokenC = new Token("tokenC", "C", INIT_SUPPLY);
        tokenD = new Token("tokenD", "D", INIT_SUPPLY);
        tokenE = new Token("tokenE", "E", INIT_SUPPLY);

        tokenA.approve(address(router), INIT_SUPPLY);
        tokenB.approve(address(router), INIT_SUPPLY);
        tokenC.approve(address(router), INIT_SUPPLY);
        tokenD.approve(address(router), INIT_SUPPLY);
        tokenE.approve(address(router), INIT_SUPPLY);

        _addLiquidity(address(tokenA), address(tokenB), 17 ether, 10 ether);
        _addLiquidity(address(tokenA), address(tokenC), 11 ether, 7 ether);
        _addLiquidity(address(tokenA), address(tokenD), 15 ether, 9 ether);
        _addLiquidity(address(tokenA), address(tokenE), 21 ether, 5 ether);
        _addLiquidity(address(tokenB), address(tokenC), 36 ether, 4 ether);
        _addLiquidity(address(tokenB), address(tokenD), 13 ether, 6 ether);
        _addLiquidity(address(tokenB), address(tokenE), 25 ether, 3 ether);
        _addLiquidity(address(tokenC), address(tokenD), 30 ether, 12 ether);
        _addLiquidity(address(tokenC), address(tokenE), 10 ether, 8 ether);
        _addLiquidity(address(tokenD), address(tokenE), 60 ether, 25 ether);

        tokenB.transfer(arbitrager, 5 ether);

        vm.stopPrank();
    }

    function _addLiquidity(address token0, address token1, uint256 token0Amount, uint256 token1Amount) internal {
        router.addLiquidity(
            token0, token1, token0Amount, token1Amount, token0Amount, token1Amount, admin, block.timestamp
        );
    }
}
