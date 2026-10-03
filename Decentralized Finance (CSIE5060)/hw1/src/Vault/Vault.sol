// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Unsafe Vault
/// @author LouisTsai
/// @notice This contract acts as a vault for ERC20 tokens, allowing deposits, withdrawals, and the conversion between assets and shares.
/// @dev Implements IVault interface with ERC20 functionality to handle tokenized share accounting for deposits and withdrawals.
interface IVault {
    function asset() external view returns (IERC20);
    function totalAssets() external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function deposit(uint256 assets, address receiver) external returns (uint256);
    function withdraw(uint256 shares, address receiver, address owner) external returns (uint256);
}

contract Vault is IVault, ERC20 {
    IERC20 private immutable _asset;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(IERC20 asset_) ERC20("Vault", "VT") {
        require(address(asset_) != address(0), "Vault: asset is the zero address");
        _asset = asset_;
    }

    function asset() public view returns (IERC20) {
        return _asset;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function totalAssets() public view override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    function convertToShares(uint256 assets) public view override returns (uint256) {
        return totalSupply() == 0 ? assets : assets * totalSupply() / totalAssets();
    }

    function convertToAssets(uint256 shares) public view override returns (uint256) {
        return shares * totalAssets() / totalSupply();
    }

    function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
        shares = convertToShares(assets);
        _balances[receiver] += shares;
        _totalSupply += shares;
        emit Transfer(address(0), receiver, shares);

        _asset.transferFrom(msg.sender, address(this), assets);
        return shares;
    }

    function withdraw(uint256 shares, address receiver, address owner) public override returns (uint256 assets) {
        require(_balances[owner] >= shares, "Vault: withdraw amount exceeds balance");
        assets = convertToAssets(shares);
        _balances[owner] -= shares;
        _totalSupply -= shares;
        emit Transfer(owner, address(0), shares);

        _asset.transfer(receiver, assets);
        return assets;
    }
}
