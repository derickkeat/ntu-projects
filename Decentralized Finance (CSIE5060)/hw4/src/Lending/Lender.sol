// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract Lender is ReentrancyGuard, Ownable {
    // State Variables
    address[] public allowedTokens;
    mapping(address => address) public tokenToPriceFeed;
    mapping(address => mapping(address => uint256)) public accountToTokenDeposits;
    mapping(address => mapping(address => uint256)) public accountToTokenBorrows;

    // Constant Variable
    uint256 public constant LIQUIDATION_REWARD = 5; // 5% Liquidation Reward
    uint256 public constant LIQUIDATION_FACTOR = 80; // At 80% Loan to Value Ratio, the loan can be liquidated
    uint256 public constant CLOSE_FACTOR = 50; // Only 50% of asset can be liquidated at one time
    uint256 public constant MIN_HEALTH_FACTOR = 1e18;

    // event
    event AllowedTokenConfiguration(address indexed token, address indexed priceFeed);
    event TokenSupply(address indexed account, address indexed token, uint256 indexed amount);
    event TokenBorrow(address indexed account, address indexed token, uint256 indexed amount);
    event TokenWithdraw(address indexed account, address indexed token, uint256 indexed amount);
    event TokenRepay(address indexed account, address indexed token, uint256 indexed amount);
    event Liquidate(
        address indexed account,
        address indexed repayToken,
        address indexed rewardToken,
        uint256 halfDebtInEth,
        address liquidator
    );

    // Error
    error TransferFailed();
    error TokenNotAllowed(address token);
    error NeedsMoreThanZero();

    // Modifier

    // Constructor
    constructor() Ownable(msg.sender) {}

    function supply(address token, uint256 amount) external {
        bool isTokenAllowed;
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (allowedTokens[i] == token) {
                isTokenAllowed = true;
                break;
            }
        }
        if (!isTokenAllowed) {
            revert("Token Not Allowed");
        }

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        accountToTokenDeposits[msg.sender][token] += amount;
        emit TokenSupply(msg.sender, token, amount);
    }

    function withdraw(address token, uint256 amount) external {
        bool isTokenAllowed;
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (allowedTokens[i] == token) {
                isTokenAllowed = true;
                break;
            }
        }
        if (!isTokenAllowed) {
            revert("Token Not Allowed");
        }
        
        if(accountToTokenDeposits[msg.sender][token] < amount) {
            revert("Insufficient Funds");
        }
        
        accountToTokenDeposits[msg.sender][token] -= amount;
        if(healthFactor(msg.sender) < MIN_HEALTH_FACTOR) {
            accountToTokenDeposits[msg.sender][token] -= amount;
            revert("Insolvency Risk");
        }

        IERC20(token).transfer(msg.sender, amount);
        emit TokenWithdraw(msg.sender, token, amount);
    }

    function borrow(address token, uint256 amount) external {
        bool isTokenAllowed = false;
        for(uint256 i = 0; i < allowedTokens.length; i++) {
            if(token == allowedTokens[i]) {
                isTokenAllowed = true;
                break;
            }
        }
        if(!isTokenAllowed) {
            revert("Token Not Allowed");
        }

        if(IERC20(token).balanceOf(address(this)) < amount) {
            revert("Insufficient borrowable tokens");
        }

        accountToTokenBorrows[msg.sender][token] += amount;
        if(healthFactor(msg.sender) < MIN_HEALTH_FACTOR) {
            accountToTokenBorrows[msg.sender][token] -= amount;
            revert("Insolvency Risk");
        }

        IERC20(token).transfer(msg.sender, amount);
        emit TokenBorrow(msg.sender, token, amount);
    }

    function repay(address token, uint256 amount) external {
        bool isTokenAllowed = false;
        for(uint256 i = 0; i < allowedTokens.length; i++) {
            if(token == allowedTokens[i]) {
                isTokenAllowed = true;
                break;
            }
        }
        if(!isTokenAllowed) {
            revert("Token Not Allowed");
        }
        if(amount > accountToTokenBorrows[msg.sender][token]) {
            revert("Excessive Repayment");
        }
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        accountToTokenBorrows[msg.sender][token] -= amount;
        emit TokenRepay(msg.sender, token, amount);
    }

    function liquidate(address account, address repayToken, address rewardToken) external {
        
    }

    function viewCollateral(address user) public view returns (uint256) {
        uint256 totalCollateralInEth;
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            address token = allowedTokens[i];
            uint256 tokenValueInEth = getValueInETH(token, accountToTokenDeposits[user][token]);
            totalCollateralInEth += tokenValueInEth;
        }
        return totalCollateralInEth;
    }

    function viewDebt(address user) public view returns (uint256) {
        uint256 totalDebtInEth;
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            address token = allowedTokens[i];
            uint256 tokenValueInEth = getValueInETH(token, accountToTokenBorrows[user][token]);
            totalDebtInEth += tokenValueInEth;
        }
        return totalDebtInEth;
    }

    function getValueInETH(address token, uint256 amount) public view returns (uint256) {
        address priceFeed = tokenToPriceFeed[token];
        (, int256 price, , , ) = AggregatorV3Interface(priceFeed).latestRoundData();
        return uint256(price) * amount / 1e18;
    }

    function getTokenValueFromEth(address token, uint256 totalValueInETH) public view returns (uint256) {
        address priceFeed = tokenToPriceFeed[token];
        (, int256 price, , , ) = AggregatorV3Interface(priceFeed).latestRoundData();
        return totalValueInETH * 1e18 / uint256(price);
    }

    function healthFactor(address account) public view returns (uint256) {
        uint256 collateralValue = viewCollateral(account);
        uint256 debtValue = viewDebt(account);
        if (debtValue == 0) {
            return 100e18;
        }
        return collateralValue * 1e18 * LIQUIDATION_FACTOR / 100 / debtValue;
    }

    function setAllowedToken(address token, address priceFeed) external onlyOwner {
        allowedTokens.push(token);
        tokenToPriceFeed[token] = priceFeed;
        emit AllowedTokenConfiguration(token, priceFeed);
    }
}
