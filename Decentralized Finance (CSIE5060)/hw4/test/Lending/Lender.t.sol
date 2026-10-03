// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Test, console2} from "forge-std/Test.sol";

import {LenderBaseTest, LoanToken, MockChainlinkOracle} from "./LenderBase.t.sol";

contract LenderTest is LenderBaseTest {
    /////////////////////////////////////////////////////////////////
    ////////////////////    setAllowedToken   ////////////////////////
    /////////////////////////////////////////////////////////////////

    event AllowedTokenConfiguration(address indexed token, address indexed priceFeed);

    function testSetMultipleAllowedToken() public {
        address[] memory tokens = new address[](3);
        tokens[0] = address(token0);
        tokens[1] = address(token1);
        tokens[2] = address(token2);

        address[] memory oracles = new address[](3);
        oracles[0] = address(oracle0);
        oracles[1] = address(oracle1);
        oracles[2] = address(oracle2);

        for (uint256 i = 0; i < tokens.length; i++) {
            // Expect an event for each token being allowed
            vm.expectEmit(true, true, true, true);
            emit AllowedTokenConfiguration(tokens[i], oracles[i]);

            // Set the allowed token and its oracle
            vm.prank(owner);
            lender.setAllowedToken(tokens[i], oracles[i]);

            // Verify the token-to-price feed mapping and allowed token list
            assertEq(lender.tokenToPriceFeed(tokens[i]), oracles[i]);
            assertEq(lender.allowedTokens(i), tokens[i]);
        }

        // Re-set Allowed Token 0 with a new oracle
        MockChainlinkOracle oracle = new MockChainlinkOracle();

        vm.expectEmit(true, true, true, true);
        emit AllowedTokenConfiguration(address(token0), address(oracle));

        vm.prank(owner);
        lender.setAllowedToken(address(token0), address(oracle));
        assertEq(lender.tokenToPriceFeed(address(token0)), address(oracle));
    }

    /////////////////////////////////////////////////////////////////
    ///////////////////////////    Supply    /////////////////////////
    /////////////////////////////////////////////////////////////////

    function testSupplyForMultipleTokens() public {
        _setAllowedTokens();

        uint256 amount = 10 ether;

        // Define tokens and initialize balances
        IERC20[] memory tokens = new IERC20[](3);
        tokens[0] = token0;
        tokens[1] = token1;
        tokens[2] = token2;

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 lenderBalance = tokens[i].balanceOf(address(lender)); // Lender Balance
            uint256 userBalance = tokens[i].balanceOf(address(user)); // User Balance
            uint256 userDeposits = lender.accountToTokenDeposits(address(user), address(tokens[i])); // Account Deposits

            vm.startPrank(user);

            tokens[i].approve(address(lender), amount);
            lender.supply(address(tokens[i]), amount);

            // Assert balances and deposits
            assertEq(tokens[i].balanceOf(address(lender)), lenderBalance + amount);
            assertEq(tokens[i].balanceOf(address(user)), userBalance - amount);
            assertEq(lender.accountToTokenDeposits(address(user), address(tokens[i])), userDeposits + amount);
            assertEq(lender.healthFactor(user), 100e18);

            vm.stopPrank();
        }
    }

    /////////////////////////////////////////////////////////////////
    ///////////////////////////    Borrow    /////////////////////////
    /////////////////////////////////////////////////////////////////

    event TokenBorrow(address indexed account, address indexed token, uint256 indexed amount);

    function testBorrowForMultipleTokens() public {
        _supplyAllTokens();

        uint256 amount = 50 ether;

        vm.prank(user);
        token2.approve(address(lender), amount);

        vm.prank(user);
        lender.supply(address(token2), amount);

        assertEq(lender.healthFactor(user), 100e18);
        assertEq(lender.viewCollateral(user), 150 ether);
        assertEq(lender.viewDebt(user), 0);

        // Collateral Value: 50 ether * 3 = 150 ether
        // Maximum Borrow Value: 150 ether * 0.8 = 120 ether

        // Borrowed Asset: 120 ether

        address[] memory tokens = new address[](2);
        tokens[0] = address(token0);
        tokens[1] = address(token1);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 50 ether;
        amounts[1] = 35 ether;

        uint256 borrowValue = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 balanceBefore = IERC20(tokens[i]).balanceOf(user);

            borrowValue += lender.getValueInETH(address(tokens[i]), amounts[i]);

            vm.prank(user);
            vm.expectEmit(true, true, true, true);
            emit TokenBorrow(user, tokens[i], amounts[i]);
            lender.borrow(tokens[i], amounts[i]);

            assertEq(lender.viewDebt(user), borrowValue);

            assertEq(balanceBefore + amounts[i], IERC20(tokens[i]).balanceOf(user));
        }

        assertEq(lender.viewCollateral(user), 150 ether);
        assertEq(lender.viewDebt(user), 120 ether);
        assertEq(lender.healthFactor(user), 1e18);
    }

    function testBorrowForMultipleTokensAmountNotEnough() public {
        _supplyAllTokens();

        uint256 amount;

        amount = 50 ether;

        vm.prank(user);
        token2.approve(address(lender), amount);

        vm.prank(user);
        lender.supply(address(token2), amount);

        // Collateral Value: 50 ether * 3 = 150 ether
        // Maximum Borrow Value: 150 ether * 0.8 = 120 ether

        // Borrowed Asset: 120 ether * 1 (Token0 not enough)

        amount = 120 ether;

        vm.prank(user);
        vm.expectRevert("Insufficient borrowable tokens");
        lender.borrow(address(token0), amount);
    }

    function testBorrowForMultipleTokensUnhealthyPosition() public {
        _supplyAllTokens();

        uint256 amount;

        amount = 50 ether;

        vm.prank(user);
        token2.approve(address(lender), amount);

        vm.prank(user);
        lender.supply(address(token2), amount);

        // Collateral Value: 50 ether * 3 = 150 ether
        // Maximum Borrow Value: 150 ether * 0.8 = 120 ether

        // Borrowed Asset: 50 ether * 1 + 50 ether * 2 = 150 ether (Unhealth Position)

        address[] memory tokens = new address[](2);
        tokens[0] = address(token0);
        tokens[1] = address(token1);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 50 ether;
        amounts[1] = 50 ether;

        vm.prank(user);
        lender.borrow(address(token0), 50 ether);

        vm.prank(user);
        vm.expectRevert("Insolvency Risk");
        lender.borrow(address(token1), 50 ether);
    }

    /////////////////////////////////////////////////////////////////
    //////////////////////////    Withdraw    ////////////////////////
    /////////////////////////////////////////////////////////////////

    event TokenWithdraw(address indexed account, address indexed token, uint256 indexed amount);

    function testWithdrawMultipleTokens() public {
        _supplyAllTokens();

        uint256 amount;
        uint256 balance;

        IERC20[] memory tokens = new IERC20[](3);
        tokens[0] = token0;
        tokens[1] = token1;
        tokens[2] = token2;

        for (uint256 i = 0; i < tokens.length; i++) {
            balance = tokens[i].balanceOf(user);
            vm.startPrank(user);
            tokens[i].approve(address(lender), balance);
            lender.supply(address(tokens[i]), balance);
            vm.stopPrank();
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            vm.startPrank(user);
            amount = lender.accountToTokenDeposits(user, address(tokens[i]));
            balance = tokens[i].balanceOf(user);
            vm.expectEmit(true, true, true, true);
            emit TokenWithdraw(user, address(tokens[i]), amount);
            lender.withdraw(address(tokens[i]), amount);

            assertEq(lender.accountToTokenDeposits(user, address(tokens[i])), 0);
            assertEq(tokens[i].balanceOf(user), balance + amount);
            vm.stopPrank();
        }
    }

    function testWithdrawMultipleTokensAmountNotEnough() public {
        _supplyAllTokens();

        uint256 amount;
        uint256 balance;

        IERC20[] memory tokens = new IERC20[](3);
        tokens[0] = token0;
        tokens[1] = token1;
        tokens[2] = token2;

        for (uint256 i = 0; i < tokens.length; i++) {
            balance = tokens[i].balanceOf(user);
            vm.startPrank(user);
            tokens[i].approve(address(lender), balance);
            lender.supply(address(tokens[i]), balance);
            vm.stopPrank();
        }

        vm.startPrank(user);
        amount = lender.accountToTokenDeposits(user, address(token0));
        vm.expectRevert("Insufficient Funds");
        lender.withdraw(address(token0), amount + 1);
    }

    function testWithdrawMultipleTokensUnhealthyPosition() public {
        _supplyAllTokens();

        uint256 amount;

        amount = 50 ether;

        vm.startPrank(user);
        token2.approve(address(lender), amount);
        lender.supply(address(token2), amount);
        vm.stopPrank();

        // Collateral Value: 50 ether * 3 = 150 ether
        // Maximum Borrow Value: 150 ether * 0.8 = 120 ether

        // Borrowed Asset: 50 ether * 1 + 50 ether * 2 = 150 ether (Unhealth Position)

        address[] memory tokens = new address[](2);
        tokens[0] = address(token0);
        tokens[1] = address(token1);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 50 ether;
        amounts[1] = 35 ether;

        for (uint256 i = 0; i < tokens.length; i++) {
            vm.startPrank(user);
            lender.borrow(address(tokens[i]), amounts[i]);
            vm.stopPrank();
        }

        vm.prank(user);
        vm.expectRevert("Insolvency Risk");
        lender.withdraw(address(token2), 1 ether);
    }

    /////////////////////////////////////////////////////////////////
    ///////////////////////////    Repay    //////////////////////////
    /////////////////////////////////////////////////////////////////

    function testRepayMultipleTokens() public {
        _setAllowedTokens();

        _setAllOraclePrice();

        IERC20[] memory tokens = new IERC20[](3);
        tokens[0] = token0;
        tokens[1] = token1;
        tokens[2] = token2;

        for (uint256 i = 0; i < tokens.length; i++) {
            vm.startPrank(owner);
            tokens[i].approve(address(lender), tokens[i].balanceOf(owner));
            lender.supply(address(tokens[i]), tokens[i].balanceOf(owner));
            vm.stopPrank();
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            vm.startPrank(user);
            tokens[i].approve(address(lender), tokens[i].balanceOf(user));
            lender.supply(address(tokens[i]), tokens[i].balanceOf(user));
            vm.stopPrank();
        }

        // Collateral Value: 50 ether * 1 + 50 ether * 2 + 50 ether * 3 = 300 ether
        // Borrowable Value: 300 ether * 0.8 = 240 ether

        uint256 amount = 10 ether;

        for (uint256 i = 0; i < tokens.length; i++) {
            address tokenAddress = address(tokens[i]);

            // Get initial balances and borrow amounts
            uint256 borrowBalance = lender.accountToTokenBorrows(user, tokenAddress);
            uint256 tokenBalance = tokens[i].balanceOf(user);

            // Borrow tokens
            vm.startPrank(user);
            lender.borrow(tokenAddress, amount);
            assertEq(lender.accountToTokenBorrows(user, tokenAddress), borrowBalance + amount);

            // Repay tokens
            tokens[i].approve(address(lender), amount);
            lender.repay(tokenAddress, amount);
            assertEq(tokens[i].balanceOf(user), tokenBalance);
            assertEq(lender.accountToTokenBorrows(user, tokenAddress), borrowBalance);
            vm.stopPrank();
        }
    }

    /////////////////////////////////////////////////////////////////
    ///////////////////////////    Liquidate    //////////////////////
    /////////////////////////////////////////////////////////////////

    function testLiquidateMultipleTokens() public {
        _supplyAllTokens();

        uint256 amount = 50 ether;

        vm.prank(user);
        token2.approve(address(lender), amount);

        vm.prank(user);
        lender.supply(address(token2), amount);

        // Collateral Value: 50 ether * 3 = 150 ether
        // Maximum Borrow Value: 150 ether * 0.8 = 120 ether

        // Borrowed Asset: 120 ether

        address[] memory tokens = new address[](2);
        tokens[0] = address(token0);
        tokens[1] = address(token1);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 50 ether;
        amounts[1] = 35 ether;

        for (uint256 i = 0; i < tokens.length; i++) {
            vm.prank(user);
            lender.borrow(tokens[i], amounts[i]);
        }

        // Due to market volatility, the price of token2 drops to 2 ether
        // Collateral Value: 50 ether * 2 = 100 ether
        // Borroed Value: 50 ether * 1 + 35 ether * 2 = 120 ether
        // Health Factor: 100 ether * 0.8 * 1e18 / 120 ether < 1e18

        _setOraclePrice(oracle2, 2 ether);

        assertLt(lender.healthFactor(user), MIN_HEALTH_FACTOR);

        vm.startPrank(liquidator);

        address repayToken = address(token0);
        address rewardToken = address(token2);

        uint256 repayTokenAmount = token0.balanceOf(liquidator);
        uint256 rewardTokenAmount = token2.balanceOf(liquidator);

        uint256 debt = lender.accountToTokenBorrows(user, repayToken);
        uint256 liquidableDebt = debt * CLOSE_FACTOR / 100;
        uint256 rewardValueInETH = lender.getValueInETH(repayToken, liquidableDebt) * LIQUIDATION_REWARD / 100;
        uint256 rewardAmount = lender.getTokenValueFromEth(
            rewardToken, rewardValueInETH + lender.getValueInETH(repayToken, liquidableDebt)
        );

        token0.approve(address(lender), liquidableDebt);
        lender.liquidate(user, repayToken, rewardToken);

        assertEq(token0.balanceOf(liquidator), repayTokenAmount - liquidableDebt);
        assertEq(token2.balanceOf(liquidator), rewardTokenAmount + rewardAmount);

        console2.log("liquidable debt", liquidableDebt / 1e18);
        console2.log("rewardAmount", rewardAmount / 1e18);
        vm.stopPrank();
    }

    /////////////////////////////////////////////////////////////////
    ///////////////////////    getValueInETH    ////////////////////////
    /////////////////////////////////////////////////////////////////

    function testgetValueInETH(int256 answer) public {
        // The price range is within (0, 10) ether
        vm.assume(answer > 0 && answer < 10 ether);

        _setAllowedTokens();
        // For Oracle
        uint80 roundId;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;

        // Variable
        uint256 price;
        uint256 amount;

        vm.prank(market);

        oracle0.setLatestRoundData(roundId, answer, startedAt, updatedAt, answeredInRound);

        amount = 1 ether;
        price = lender.getValueInETH(address(token0), amount);
        assertEq(price, uint256(answer));
    }

    /////////////////////////////////////////////////////////////////
    ///////////////////    getTokenValueFromEth    //////////////////
    /////////////////////////////////////////////////////////////////

    function testGetTokenValueFromEth(uint256 value) public {
        vm.assume(value > 0 && value < 10 ether);
        _setAllowedTokens();
        // For Oracle
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;

        // Variable
        uint256 amount;

        answer = 2 ether; // 1 token0 is worth 2 ether
        vm.prank(market);
        oracle0.setLatestRoundData(roundId, answer, startedAt, updatedAt, answeredInRound);

        amount = lender.getTokenValueFromEth(address(token0), value);
        assertEq(amount, value * 1e18 / uint256(answer));
    }

    /////////////////////////////////////////////////////////////////
    //////////////////    viewCollateral    ///////////////
    /////////////////////////////////////////////////////////////////

    function testViewCollateral(uint256 amount) public {
        vm.assume(amount > 0 && amount < 10 ether);

        _setAllowedTokens();

        _setAllOraclePrice();

        IERC20[] memory tokens = new IERC20[](3);
        tokens[0] = token0;
        tokens[1] = token1;
        tokens[2] = token2;

        for (uint256 i = 0; i < tokens.length; i++) {
            vm.startPrank(user);
            tokens[i].approve(address(lender), amount);
            lender.supply(address(tokens[i]), amount);
            vm.stopPrank();
        }

        uint256 accountCollateralValue = lender.viewCollateral(user);
        assertEq(accountCollateralValue, 6 ether * amount / 1 ether);
    }

    //////////////////////////////////////////////////////////////////
    ////////////////////    Allowed Token Check    ///////////////////
    /////////////////////////////////////////////////////////////////

    // setAllowedToken Function
    function testSetAllowedTokenNotOwner() public {
        address[] memory tokens = new address[](3);
        tokens[0] = address(token0);
        tokens[1] = address(token1);
        tokens[2] = address(token2);

        address[] memory oracles = new address[](3);
        oracles[0] = address(oracle0);
        oracles[1] = address(oracle1);
        oracles[2] = address(oracle2);

        for (uint256 i = 0; i < tokens.length; i++) {
            vm.expectRevert();
            lender.setAllowedToken(tokens[i], oracles[i]);
        }
    }

    // supply function
    function testSupplyNotAllowedTokens() public {
        vm.prank(user);
        token0.approve(address(lender), 10 ether);

        vm.prank(user);
        vm.expectRevert("Token Not Allowed");
        lender.supply(address(token0), 10 ether);
    }

    // borrow function
    function testBorrowNotAllowedTokens() public {
        _supplyAllTokens();

        uint256 amount = 50 ether;

        vm.prank(user);
        token2.approve(address(lender), amount);

        vm.prank(user);
        lender.supply(address(token2), amount);

        vm.prank(user);
        LoanToken token = new LoanToken();

        vm.prank(user);
        vm.expectRevert("Token Not Allowed");
        lender.borrow(address(token), amount);
    }

    // withdraw function
    function testWithdrawNotAllowedTokens() public {
        _supplyAllTokens();

        vm.prank(user);
        LoanToken token = new LoanToken();

        vm.prank(user);
        vm.expectRevert("Token Not Allowed");
        lender.withdraw(address(token), 50 ether);
    }

    function testRepayNotAllowedTokens() public {
        _supplyAllTokens();

        uint256 amount = 50 ether;

        vm.prank(user);
        token2.approve(address(lender), amount);

        vm.prank(user);
        lender.supply(address(token2), amount);

        vm.prank(user);
        lender.borrow(address(token1), 10 ether);

        vm.prank(user);
        LoanToken token = new LoanToken();

        vm.prank(user);
        vm.expectRevert("Token Not Allowed");
        lender.repay(address(token), 50 ether);
    }

    /////////////////////////////////////////////////////////////////
    ///////////////////////    Internal Helper    ////////////////////
    /////////////////////////////////////////////////////////////////

    function _setAllowedTokens() internal {
        address[] memory tokens = new address[](3);
        tokens[0] = address(token0);
        tokens[1] = address(token1);
        tokens[2] = address(token2);

        address[] memory oracles = new address[](3);
        oracles[0] = address(oracle0);
        oracles[1] = address(oracle1);
        oracles[2] = address(oracle2);

        for (uint256 i = 0; i < tokens.length; i++) {
            vm.prank(owner);
            lender.setAllowedToken(tokens[i], oracles[i]);
        }
    }

    function _setOraclePrice(MockChainlinkOracle oracle, int256 answer) internal {
        uint80 roundId;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;

        vm.prank(market);
        oracle.setLatestRoundData(roundId, answer, startedAt, updatedAt, answeredInRound);
    }

    function _setAllOraclePrice() internal {
        int256[] memory answers = new int256[](3);
        MockChainlinkOracle[] memory oracles = new MockChainlinkOracle[](3);

        answers[0] = 1 ether;
        answers[1] = 2 ether;
        answers[2] = 3 ether;

        oracles[0] = oracle0;
        oracles[1] = oracle1;
        oracles[2] = oracle2;

        for (uint256 i = 0; i < 3; i++) {
            _setOraclePrice(oracles[i], answers[i]);
        }
    }

    function _supplyAllTokens() internal {
        _setAllowedTokens();

        _setAllOraclePrice();

        IERC20[] memory tokens = new IERC20[](3);
        tokens[0] = token0;
        tokens[1] = token1;
        tokens[2] = token2;

        for (uint256 i = 0; i < tokens.length; i++) {
            vm.startPrank(owner);
            tokens[i].approve(address(lender), tokens[i].balanceOf(owner));
            lender.supply(address(tokens[i]), tokens[i].balanceOf(owner));
            vm.stopPrank();
        }
    }
}
