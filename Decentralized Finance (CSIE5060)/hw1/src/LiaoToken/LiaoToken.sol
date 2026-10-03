// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract LiaoToken is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => bool) isClaim;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    event Claim(address indexed user, uint256 indexed amount);

    constructor(string memory name_, string memory symbol_) payable {
        _name = name_;
        _symbol = symbol_;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function claim() external returns (bool) {
        require(!isClaim[msg.sender], "Already claimed");
        _balances[msg.sender] += 1 ether;
        _totalSupply += 1 ether;
        isClaim[msg.sender] = true;
        emit Claim(msg.sender, 1 ether);
        emit Transfer(address(0), msg.sender, 1 ether);
        return true;
    }

    // TODO: Implement transfer function
    function transfer(address to, uint256 amount) external returns (bool) {
        require(_balances[msg.sender] > amount, "Not Enough Balance.");
        
        _balances[to] += amount;
        _balances[msg.sender] -= amount;

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    // TODO: Implement transferFrom function
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(_balances[from] >= value, "Not Enough Balance.");
        require(_allowances[from][msg.sender] >= value, "Not Enough Allowance.");

        _allowances[from][msg.sender] -= value;
        _balances[from] -= value;
        _balances[to] += value;

        emit Transfer(from, to, value);

        return true;
    }
    
    // TODO: Implement approve function
    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] += amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }
    
    // TODO: Implement allowance function
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }
}
