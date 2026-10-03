// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Untrusted Oracle
/// @author LouisTsai
/// @notice Price feed oracle that returns USD price
/// @dev The price feed does not depend on a single source; instead, users can submit their own price feeds, and the owner will calculate the average price to determine the final price.

contract UntrustedOracle {
    /// State Variable
    address public oracle0;
    address public oracle1;

    uint256 public finalPrice;
    address public owner;

    bytes4 constant setOraclePrice = bytes4(keccak256("setOraclePrice(uint256)"));
    bytes4 constant getOraclePrice = bytes4(keccak256("getOraclePrice()"));

    /// Error
    error notOwner(address user);

    /// Modifier
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert notOwner(msg.sender);
        }
        _;
    }

    /// Constructor
    constructor(address _oracle0, address _oracle1) payable {
        oracle0 = _oracle0;
        oracle1 = _oracle1;
        owner = msg.sender;
    }

    function setOracle0(address _oracle) external onlyOwner {
        oracle0 = _oracle;
    }

    function setOracle1(address _oracle) external onlyOwner {
        oracle1 = _oracle;
    }

    function setOracle0Price(uint256 _price) external {
        (bool success,) = oracle0.delegatecall(abi.encodePacked(setOraclePrice, _price));
        require(success);
    }

    function setOracle1Price(uint256 _price) external {
        (bool success,) = oracle1.delegatecall(abi.encodePacked(setOraclePrice, _price));
        require(success);
    }

    /// @notice Finalizes the price from two oracles by averaging their latest values
    /// @dev This function retrieves price data from two separate oracle sources, averaging their results to determine a final price.
    function finalizeOraclePrice() external onlyOwner {
        bool success;
        bytes memory data;

        // Attempt to fetch the price from the first oracle using delegatecall
        (success, data) = oracle0.delegatecall(abi.encodePacked(getOraclePrice));
        require(success, "Oracle 0 fetch failed");

        // Decode the data returned from the first oracle
        uint256 _price0 = abi.decode(data, (uint256));

        // Attempt to fetch the price from the second oracle using delegatecall
        (success, data) = oracle1.delegatecall(abi.encodePacked(getOraclePrice));
        require(success, "Oracle 1 fetch failed");

        // Decode the data returned from the second oracle
        uint256 _price1 = abi.decode(data, (uint256));

        // Average the prices obtained from both oracles
        finalPrice = (_price0 + _price1) / 2;
    }

    function getFinalizeOraclePrice() external view returns (uint256) {
        return finalPrice;
    }
}

contract OraclePriceStorage {
    uint256 price;

    function setOraclePrice(uint256 _price) external {
        price = _price;
    }

    function getOraclePrice() external view returns (uint256) {
        return price;
    }
}
