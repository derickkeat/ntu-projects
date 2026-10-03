// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Multisig {
    uint256 internal constant signerNum = 5;
    uint256 internal constant threshold = 3;

    address[signerNum] public signers;
    mapping(address => bool) public isSigner;

    struct Transaction {
        uint256 id;
        address payable target;
        bytes data;
        bool execute;
        uint256 confirmationCount;
    }

    Transaction[] public transactions;

    function isValidSigner(address addr) public view returns (bool) {
        return isSigner[addr];
    }

    function isTransactionExists(uint256 index) public view returns (bool) {
        return index < transactions.length;
    }

    function isTransactionExecute(uint256 index) public view returns (bool) {
        if (index >= transactions.length) return false;
        return transactions[index].execute;
    }

    constructor(address[signerNum] memory signerList) payable {
        require(signerList.length == signerNum, "Length Not Matched");
        for (uint256 i = 0; i < signerNum; i++) {
            signers[i] = signerList[i];
            isSigner[signerList[i]] = true;
        }
    }

    receive() external payable {}

    fallback() external payable {}

    function submitTransaction(address payable target, bytes memory data) external payable returns (uint256) {
        uint256 id = transactions.length;
        transactions.push(Transaction({id: id, target: target, data: data, execute: false, confirmationCount: 0}));
        return id;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 index) public view returns (Transaction memory) {
        require(isTransactionExists(index), "Transaction Not Exists");
        return transactions[index];
    }

    function isUniqueAddress(address[] memory addr) public pure returns (bool) {
        uint256 length = addr.length;
        for (uint256 i = 0; i < length; i++) {
            if (addr[i] == addr[(i + 1) % length]) return false;
        }
        return true;
    }

    function confirmTransaction(uint256 index, bytes[] memory signature, address[] memory signerList) external {
        require(isTransactionExists(index), "Transaction Not Exists");
        require(!isTransactionExecute(index), "Transaction Already Executed");

        require(signerList.length >= threshold, "Threshold Not Passed");
        require(isUniqueAddress(signerList), "Not Unique Signers");

        require(signature.length == signerList.length, "Length Not Matched");

        uint256 validSignatures = 0;
        bytes32 message = genMessage(index);
        for (uint256 i = 0; i < signerList.length; i++) {
            address recoveredSigner = recoverSigner(message, signature[i]);
            require(recoveredSigner == signerList[i], "Invalid signature");
            require(isValidSigner(recoveredSigner), "Signer not authorized");
            validSignatures += 1;
        }

        require(validSignatures >= threshold, "Not Passed Threshold");

        Transaction storage transaction = transactions[index];
        transaction.confirmationCount = validSignatures;
    }

    function genMessage(uint256 index) public view returns (bytes32) {
        require(isTransactionExists(index), "Transaction Not Exists");
        uint256 id = transactions[index].id;
        address payable target = transactions[index].target;
        return keccak256(abi.encodePacked(id, target));
    }

    function recoverSigner(bytes32 _hash, bytes memory _signature) internal pure returns (address) {
        require(_signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Divide the signature into r, s and v variables
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        // Recover the signer address
        return address(ecrecover(_hash, v, r, s));
    }

    function executeTransaction(uint256 index) public payable returns (uint256) {
        require(isTransactionExists(index), "Transaction Not Exists");
        require(!isTransactionExecute(index), "Transaction Already Executed");
        Transaction storage transaction = transactions[index];

        uint256 confirmationCount = transaction.confirmationCount;
        address target = transaction.target;
        bytes memory data = transaction.data;

        require(confirmationCount >= threshold, "Threshold Not Passed");

        transaction.execute = true;

        (bool success,) = target.call{value: msg.value}(data);
        require(success, "Execution Failed");

        return index;
    }
}
