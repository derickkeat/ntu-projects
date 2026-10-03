// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title BadLender
/// @author LouisTsai
/// @notice This contract allows users to deposit Ether in exchange for tokens, withdraw their deposits, and take flash loans.
/// @dev This contract implements a token-based system where deposits and withdrawals are tracked using an ERC20 token.
interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

contract BadLender is ERC20 {
    /// State Variable
    mapping(address => uint256) public balances;

    /// Error
    error InsufficientBalance();
    error RepayFailed();
    error OperationFailed();

    /// Event
    event Deposit(address indexed depositor, uint256 amount);
    event Withdraw(address indexed withdrawer, uint256 amount);
    event FlashLoanExecuted(address borrower, uint256 amount);

    constructor() ERC20("BadLender", "BL") {}

    // Allows deposits to the pool and mints pool shares
    function deposit() external payable {
        if (msg.value == 0) revert OperationFailed();
        uint256 sharesToMint = calculateShares(msg.value);
        _mint(msg.sender, sharesToMint);
        emit Deposit(msg.sender, msg.value);
    }

    // Allows withdrawals from the pool and burns pool shares
    function withdraw(uint256 shareAmount) external {
        uint256 etherAmount = calculateEther(shareAmount);
        if (etherAmount > address(this).balance) {
            revert InsufficientBalance();
        }

        _burn(msg.sender, shareAmount);
        emit Withdraw(msg.sender, etherAmount);

        (bool sent,) = msg.sender.call{value: etherAmount}("");
        require(sent, "Failed to send Ether");
    }

    // Provides a flash loan and expects the same amount to be returned
    function flashLoan(uint256 amount) external {
        if (amount > address(this).balance) revert OperationFailed();

        uint256 balanceBefore = address(this).balance;
        (bool success,) = msg.sender.call{value: balanceBefore}("");
        require(success, "transfer failed");
        IFlashLoanEtherReceiver(msg.sender).execute();
        emit FlashLoanExecuted(msg.sender, amount);

        if (address(this).balance < balanceBefore) {
            revert RepayFailed();
        }
    }

    // Conversion between ETH and shares
    function calculateShares(uint256 depositAmount) public view returns (uint256) {
        if (totalSupply() == 0 || address(this).balance - depositAmount == 0) return depositAmount;
        return depositAmount * totalSupply() / (address(this).balance - depositAmount);
    }

    // Conversion between ETH and shares
    function calculateEther(uint256 shareAmount) public view returns (uint256) {
        if (totalSupply() == 0) return 0;
        return shareAmount * address(this).balance / totalSupply();
    }
}
