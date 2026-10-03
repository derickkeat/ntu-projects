// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BadLeaf is ERC721 {
    address internal owner;
    bytes32 root;
    uint256 id;

    mapping(bytes32 => bool) internal mintedLeaf;
    mapping(address => uint256) internal privateMintAmount;
    mapping(address => bool) internal privateMintClaimed;

    error Distributor__notOwner();

    constructor(bytes32 _root) payable ERC721("NFinTech", "NT") {
        owner = msg.sender;
        root = _root;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Distributor__notOwner();
        }
        _;
    }

    function verify(bytes32[] memory proof, bytes32 leaf) external {
        require(MerkleProof.verify(proof, root, leaf), "Not on the whitelist");
        require(mintedLeaf[leaf] == false, "Already Minted");
        mintedLeaf[leaf] = true;
        id += 1;
        _safeMint(msg.sender, id);
    }

    function getLeafNode(address addr, uint256 number) external pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(addr, number))));
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function mint(address addr) external onlyOwner returns (uint256) {
        require(privateMintAmount[addr] != 0, "No more NFT to claim");
        require(privateMintClaimed[addr] == false, "Already claimed!");

        privateMintAmount[addr] -= 1;

        if (privateMintAmount[addr] == 0) {
            privateMintClaimed[addr] = true;
        }

        id += 1;
        _safeMint(addr, id);
        return id;
    }

    function addPrivateSale(address addr, uint256 amount) external onlyOwner returns (uint256) {
        require(privateMintClaimed[addr] == false, "Cannot add private sales twice");
        require(privateMintAmount[addr] == 0, "Cannot update the private sales");
        require(amount != 0, "Zero private sales amount");

        privateMintAmount[addr] = amount;
        return amount;
    }
}
