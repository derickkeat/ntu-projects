// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title BadCaller
/// @author LouisTsai
/// @notice This contract allows users to deposit and withdraw ERC20 tokens, and provides flash loan services.
/// @dev This contract integrates reentrancy protection and uses ERC20 tokens for its operations.
contract BadCaller {
    /// State Variable
    uint256 internal lock;
    uint256 public feeRate;

    mapping(address => uint256) public balances;

    IERC20 public loanToken;

    /// Event
    event Deposit(address indexed depositor, uint256 amount);
    event Withdraw(address indexed withdrawer, uint256 amount);
    event FlashLoan(address indexed borrower, uint256 amount, uint256 fee);

    /// Modifier
    modifier nonReentrant() {
        if (lock == 1) revert();
        lock = 1;
        _;
        lock = 0;
    }

    /// @notice Constructs the contract with specified token and fee rate
    /// @param _loanToken The ERC20 token to be used
    /// @param _feeRate The fee rate for flash loans
    constructor(IERC20 _loanToken, uint256 _feeRate) {
        loanToken = _loanToken;
        feeRate = _feeRate;
    }

    /// @notice Deposits tokens into the contract for future use
    /// @dev Transfers tokens from the sender to this contract and updates their balance
    /// @param amount The amount of tokens to deposit
    function deposit(uint256 amount) external nonReentrant {
        loanToken.transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    /// @notice Withdraws tokens from the contract
    /// @dev Checks user balance before transferring tokens back to them
    /// @param amount The amount of tokens to withdraw
    function withdraw(uint256 amount) external nonReentrant {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        loanToken.transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    /// @notice Returns the maximum amount available for a flash loan
    /// @dev Calculates based on the total token balance of the contract
    /// @return The maximum flash loan amount
    function maxFlashLoan() public view returns (uint256) {
        return loanToken.balanceOf(address(this));
    }

    /// @notice Returns the total assets held by the contract
    /// @dev Simply returns the current token balance
    /// @return The total assets in tokens
    function assets() public view returns (uint256) {
        return loanToken.balanceOf(address(this));
    }

    /// @notice Provides a flash loan with zero fees for old users
    /// @dev Charges a fee for new users who have never used the platform, checks for repayment
    /// @param target The address to which the funds will be sent and that will execute the transaction
    /// @param amount The amount of the loan
    /// @param data The call data to be sent to the `target` address
    function flashLoan(address target, uint256 amount, bytes calldata data) external nonReentrant {
        require(amount <= maxFlashLoan(), "Loan amount exceeds available liquidity");
        uint256 balanceBefore = assets();
        uint256 fee = balances[msg.sender] == 0 ? calculateFee(amount) : 0;

        // Transfer the loan amount to the receiver
        loanToken.transfer(address(target), amount);

        (bool success,) = target.call(data);
        require(success, "external call failed");

        // Check that the tokens plus fee are returned
        require(loanToken.balanceOf(address(this)) >= balanceBefore + fee, "Repay failed");

        emit FlashLoan(msg.sender, amount, fee);
    }

    /// @notice Calculates the fee based on the transaction amount and fee rate
    /// @dev Returns the fee in tokens
    /// @param amount The transaction amount for which the fee is calculated
    /// @return The calculated fee
    function calculateFee(uint256 amount) public view returns (uint256) {
        return amount * feeRate / 10000;
    }
}
