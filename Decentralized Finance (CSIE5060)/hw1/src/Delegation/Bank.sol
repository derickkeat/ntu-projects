// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Bank
/// @author LouisTsai
/// @notice This contract allows users to deposit and withdraw Ether securely
/// @dev This contract uses multicall to execute multiple operations in a single transaction
contract Bank {
    /// State Variable
    mapping(address => uint256) public balances;

    /// Error
    error InsufficientBalance();
    error TransferFailed();

    /// Event
    event Deposit(address indexed depositor, uint256 amount);
    event Withdraw(address indexed withdrawer, uint256 amount);

    /// @notice Deposits Ether into the contract and updates the token balance
    /// @dev Adds the deposited amount to the sender's balance and emits a Deposit event
    function deposit() external payable {
        require(msg.value > 0, "Deposit value must be greater than zero");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Withdraws Ether from the contract if the balance is sufficient
    /// @dev Subtracts the requested amount from the sender's balance and attempts to send Ether
    /// @param amount The amount of Ether (in wei) to withdraw
    function withdraw(uint256 amount) public {
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance();
        }

        balances[msg.sender] -= amount;
        (bool success,) = msg.sender.call{value: amount}("");

        if (!success) {
            revert TransferFailed();
        }

        emit Withdraw(msg.sender, amount);
    }

    /// @notice Executes multiple calls in a single transaction
    /// @dev Uses delegatecall to execute each call in the context of this contract's state
    /// @param data An array of call data to be executed
    /// @return results An array of return data from each call
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = doDelegateCall(data[i]);
        }
        return results;
    }

    function doDelegateCall(bytes memory data) private returns (bytes memory) {
        (bool success, bytes memory res) = address(this).delegatecall(data);

        if (!success) {
            revert(string(res));
        }

        return res;
    }
}
