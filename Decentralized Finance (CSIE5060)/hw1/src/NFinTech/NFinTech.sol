// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

interface IERC721TokenReceiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}


contract NFinTech is IERC721 {
    string private _name;
    string private _symbol;

    uint256 private _tokenId;

    mapping(uint256 => address) private _owner;
    mapping(address => uint256) private _balances;
    mapping(address => bool) private isClaim;

    mapping(address => mapping(address => bool)) private _operatorApproval;
    mapping(uint256 => address) _tokenApproval;


    error ZeroAddress();

    constructor(string memory name_, string memory symbol_) payable {
        _name = name_;
        _symbol = symbol_;
    }

    function claim() public {
        if (isClaim[msg.sender] == false) {
            uint256 id = _tokenId;
            _owner[id] = msg.sender;

            _balances[msg.sender] += 1;
            isClaim[msg.sender] = true;

            _tokenId += 1;
        }
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function balanceOf(address owner) public view returns (uint256) {
        if (owner == address(0)) revert ZeroAddress();
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owner[tokenId];
        if (owner == address(0)) revert ZeroAddress();
        return owner;
    }

    // TODO: Implement setApproveForAll function
    function setApprovalForAll(address operator, bool approved) external {
        require(operator != msg.sender, "ERC721: approval to caller.");
        require(operator != address(0), "Address cannot be zero.");

        _operatorApproval[msg.sender][operator] = approved;
        
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // TODO: Implement isApprovedForAll function
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _operatorApproval[owner][operator];
    }

    // TODO: Implement approve function
    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(owner == msg.sender || _operatorApproval[owner][msg.sender] == true, "The token does not belong to this user.");
        
        _tokenApproval[tokenId] = to;

        emit Approval(owner, to, tokenId);
    }
    
    // TODO: Implement getApproved function
    function getApproved(uint256 tokenId) external view returns (address) {
        return _tokenApproval[tokenId];
    }

    // TODO: Implement transferFrom function
    function transferFrom(address from, address to, uint256 tokenId) external {
        require(from == _owner[tokenId], "The token does not belong to this user.");
        require(to != address(0), "Address cannot be zero.");

        _owner[tokenId] = to;
        _balances[from] -= 1;
        _balances[to] += 1;

        emit Transfer(from, to, tokenId);
    }
    
    // TODO: Implement safeTransferFrom function
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, "");
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(_owner[tokenId] == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        
        // Clear approvals
        _approve(address(0), tokenId);
        
        // Update balances
        _balances[from] -= 1;
        _balances[to] += 1;
        // Update ownership
        _owner[tokenId] = to;
        
        emit Transfer(from, to, tokenId);
    }
    
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApproval[tokenId] = to;
        emit Approval(_owner[tokenId], to, tokenId);
    }
    
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (_isContract(to)) {
            try IERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721TokenReceiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    
    function _isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = _owner[tokenId];
        return (spender == owner ||
                _tokenApproval[tokenId] == spender ||
                _operatorApproval[owner][spender]);
    }
}
