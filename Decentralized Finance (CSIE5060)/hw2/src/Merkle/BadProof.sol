// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IBadProof {
    function mint(address addr, bytes32[] memory proof) external;
    function genNode(address addr, uint256 tokenId) external returns (bytes32);
}

contract BadProof is ERC721 {
    address internal owner;
    bytes32 internal root;
    uint256 internal id;
    mapping(address => bool) internal isMinted;

    uint256 internal constant MAX_SUPPLY = 8;

    constructor(bytes32 _root) ERC721("NFinTech", "NT") {
        owner = msg.sender;
        root = _root;
    }

    function mint(address addr, bytes32[] memory proof) external {
        bytes32 leaf = genNode(msg.sender);
        require(MerkleProof.verify(proof, root, leaf), "Not On the Whitelist");
        require(addr == msg.sender, "Caller Not Minter");
        require(isMinted[addr] == false, "Token Already Minted");
        require(id < MAX_SUPPLY, "Exceed Max Supply");

        id += 1;
        _safeMint(msg.sender, id);

        isMinted[addr] = true;
    }

    function genNode(address addr) public pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(addr))));
    }
}
