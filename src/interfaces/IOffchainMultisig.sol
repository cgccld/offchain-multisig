// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IOffchainMultisig {
    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
    }

    event Execution(uint256 indexed transactionId, address destination, uint256 value, bytes data);
    event Deposit(address indexed sender, uint256 value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 required);
}