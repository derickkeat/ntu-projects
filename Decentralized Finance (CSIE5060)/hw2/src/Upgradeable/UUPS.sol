// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Proxy {
    bytes32 internal constant implementationSlot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

    constructor(address _implementation) {
        _setImplementation(_implementation);
        (bool success,) = _implementation.delegatecall(abi.encodeWithSignature("initialize()"));
        require(success, "Initialization Failed");
    }

    fallback() external payable {
        address impl = _getImplementation();
        assembly {
            // Load free memory pointer
            let ptr := mload(0x40)
            // Copy function signature and arguments from calldata into memory
            calldatacopy(ptr, 0, calldatasize())
            // Delegatecall to the implementation
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
            // Copy the returned data
            returndatacopy(ptr, 0, returndatasize())
            // Check if the call was successful
            switch result
            case 0 { revert(ptr, returndatasize()) }
            default { return(ptr, returndatasize()) }
        }
    }

    function _getImplementation() internal view returns (address) {
        return _getAddressSlot(implementationSlot).value;
    }

    function _setImplementation(address newImplementation) internal {
        _getAddressSlot(implementationSlot).value = newImplementation;
    }

    struct Slot {
        address value;
    }

    function _getAddressSlot(bytes32 slot) internal pure returns (Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

interface ILogic {
    function getNumber() external view returns (uint256);
    function increment() external;
    function decrement() external;
}

contract Logic {
    bytes32 internal constant implementationSlot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

    bool public isInitialized;
    address public owner;
    uint256 public number;

    function initialize() external {
        require(!isInitialized, "Already Initialized");
        isInitialized = true;
        owner = msg.sender;
        number = 0;
    }

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable {
        _authorizeUpgrade();
        _upgradeToAndCall(newImplementation, data);
    }

    function _authorizeUpgrade() internal view {
        require(msg.sender == owner, "Not Owner");
    }

    function _upgradeToAndCall(address newImplementation, bytes memory data) internal {
        _setImplementation(newImplementation);
        if (data.length > 0) {
            (bool success,) = newImplementation.delegatecall(data);
            require(success, "Call failed");
        }
    }

    function _setImplementation(address newImplementation) internal {
        _getAddressSlot(implementationSlot).value = newImplementation;
    }

    struct Slot {
        address value;
    }

    function _getAddressSlot(bytes32 slot) internal pure returns (Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    function getNumber() public view returns (uint256) {
        return number;
    }

    function increment() public {
        number += 1;
    }

    function decrement() public {
        number -= 1;
    }
}
