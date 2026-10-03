// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Test, console2} from "forge-std/Test.sol";

import {Multisig} from "../../../src/Logic/Multisig.sol";

contract LiaoToken is ERC20 {
    constructor() ERC20("LoanToken", "LT") {
        _mint(msg.sender, 100 ether);
    }
}

contract MultisigBaseTest is Test {
    /// State Variable
    // Role
    address internal user0;
    address internal user1;
    address internal user2;
    address internal user3;

    address internal deployer;

    // Contract
    Multisig internal multisig;
    LiaoToken internal token;

    // Modifier
    modifier validation() {
        assertEq(token.balanceOf(address(this)), 0);
        _;
        assertEq(token.balanceOf(address(this)), 100 ether);
    }

    /// Setup function
    function setUp() public {
        // Role
        user0 = 0xF354128a0E2aB91c99F7467D0cD150A4219D69cA;
        user1 = 0x046b4b854d316DDC72a42c9DA5ABaB41f0Bdcb76;
        user2 = 0xC5932B0AdB1c65AF6Ccba5E08D70f4704c9f9a3B;
        user3 = 0xca2e2722598ca561ee0a36EB1A2722951a496A52;

        user0 = vm.addr(uint256(1337));

        deployer = 0x131f15F1fD1024551542390614B6c7e210A911AF;

        // Although the multisig is designed for 5 members, we currently have only 4 members.
        address[5] memory signer = [user0, user1, user2, user3, address(0)];

        vm.prank(deployer);
        multisig = new Multisig(signer);

        vm.prank(deployer);
        token = new LiaoToken();

        assertEq(token.balanceOf(deployer), 100 ether);

        // Oops, I accidentally transferred the token into the multisig wallet.
        vm.prank(deployer);
        token.transfer(address(multisig), 100 ether);

        assertEq(token.balanceOf(address(multisig)), 100 ether);

        // The following is not an environment setup; it demonstrates how user0 signs a message on another chain
        // and the ecrecover process. Note the characteristics and behavior of ecrecover.

        // This multisig contract is deployed on another EVM-compatible blockchain
        // user0 sign a message and get the corresponding signature.
        // The message generation is the same as the BadSignature::genMessage function
        // user0 get a signature: 0xddbfaf1f1237db98f2e8517d9c2111c6184e927a9489c3ec30a95903fd16de59110b30fee6f7fb2f440dc22d58a7a4ec2ee5966d81e3e1bf66c9473bda6a911e1b
        // It can be split into three parts: (uint8 v, bytes32 r, bytes32 s) = (28, 0x460bc5cfd21d924c344e23e57f1f8e85dc205460f6d663a0da456c2e81b2cfca, 0x606c8c1699be426fabb34a105fb3e63c68d78ed00c9b268168e71bfe18d744ef)

        bytes32 message = keccak256(abi.encodePacked(uint256(3), address(token)));

        // user0 sign a message off-chain, and get this signature
        bytes memory signature =
            hex"ddbfaf1f1237db98f2e8517d9c2111c6184e927a9489c3ec30a95903fd16de59110b30fee6f7fb2f440dc22d58a7a4ec2ee5966d81e3e1bf66c9473bda6a911e1b";

        // Divide the signature into r, s and v variables
        // Use low-level assembly operation
        bytes32 r;
        bytes32 s;
        uint8 v;

        (v, r, s) = vm.sign(uint256(1337), message);

        bytes memory sig = abi.encodePacked(bytes32(r), bytes32(s), uint8(v));

        console2.logBytes(sig);

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // Version of signature should be 27 or 28. If not, reverts
        require(v == 27 || v == 28, "Invalid signature version");

        address addr = ecrecover(message, v, r, s);

        assertEq(addr, user0);
    }
}
