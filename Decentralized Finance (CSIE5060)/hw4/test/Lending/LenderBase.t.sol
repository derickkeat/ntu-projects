// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Test, console2} from "forge-std/Test.sol";

import {Lender} from "../../src/Lending/Lender.sol";

contract LoanToken is ERC20 {
    constructor() ERC20("LoanToken", "LT") {
        _mint(msg.sender, 150 ether);
    }
}

contract MockChainlinkOracle {
    // State Variable
    address internal owner;

    // Variable
    uint80 internal roundId;
    int256 internal answer;
    uint256 internal startedAt;
    uint256 internal updatedAt;
    uint80 internal answeredInRound;

    // Modifier
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender;
    }

    // Functions
    function latestRoundData()
        external
        view
        returns (uint80 _roundId, int256 _answer, uint256 _startedAt, uint256 _updatedAt, uint80 _answeredInRound)
    {
        _roundId = roundId;
        _answer = answer;
        _startedAt = startedAt;
        _updatedAt = updatedAt;
        _answeredInRound = answeredInRound;
    }

    function setLatestRoundData(
        uint80 _roundId,
        int256 _answer,
        uint256 _startedAt,
        uint256 _updatedAt,
        uint80 _answeredInRound
    ) external onlyOwner {
        roundId = _roundId;
        answer = _answer;
        startedAt = _startedAt;
        updatedAt = _updatedAt;
        answeredInRound = _answeredInRound;
    }
}

contract LenderBaseTest is Test {
    /// State Variable
    // Role
    address internal owner;
    address internal market;
    address internal user;
    address internal liquidator;

    // Contract
    Lender internal lender;

    // Token
    LoanToken internal token0;
    LoanToken internal token1;
    LoanToken internal token2;

    // Oracle
    MockChainlinkOracle oracle0;
    MockChainlinkOracle oracle1;
    MockChainlinkOracle oracle2;

    // Constant
    uint256 public constant LIQUIDATION_REWARD = 5;
    uint256 public constant LIQUIDATION_FACTOR = 80;
    uint256 public constant CLOSE_FACTOR = 50;
    uint256 public constant MIN_HEALTH_FACTOR = 1e18;

    /// Setup function
    function setUp() public {
        // Role
        owner = makeAddr("owner");
        market = makeAddr("market");
        user = makeAddr("user");
        liquidator = makeAddr("liquidator");

        // Contract
        vm.prank(owner);
        lender = new Lender();

        // Token
        vm.startPrank(owner);
        token0 = new LoanToken();
        token1 = new LoanToken();
        token2 = new LoanToken();

        token0.transfer(user, 50 ether);
        token1.transfer(user, 50 ether);
        token2.transfer(user, 50 ether);

        token0.transfer(liquidator, 50 ether);
        token1.transfer(liquidator, 50 ether);
        token2.transfer(liquidator, 50 ether);
        vm.stopPrank();

        // Oracle
        vm.startPrank(market);
        oracle0 = new MockChainlinkOracle();
        oracle1 = new MockChainlinkOracle();
        oracle2 = new MockChainlinkOracle();
        vm.stopPrank();
    }
}
