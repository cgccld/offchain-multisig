// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IOffchainMultisig {
  struct Transaction {
    address destination;
    uint256 value;
    bytes data;
  }

  error OnlySelf();
  error InvalidAddress();
  error InvalidRequirement();
  error WrongPositionAddress();
  error OwnerDoesNotExist(address owner);
  error OwnerAlreadyExisted(address owner);
  error OwnerAlreadyConfirmed(address owner);
  error NotMetCriteria(uint256 criteria, uint256 threshold);

  event Execution(uint256 indexed transactionId, address destination, uint256 value, bytes data);
  event Deposit(address indexed sender, uint256 value);
  event OwnerAddition(address indexed owner);
  event OwnerRemoval(address indexed owner);
  event RequirementChange(uint256 required);
}
