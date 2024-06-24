// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract SigUtils {
  bytes32 internal DOMAIN_SEPARATOR;

  constructor(bytes32 _DOMAIN_SEPARATOR) {
    DOMAIN_SEPARATOR = _DOMAIN_SEPARATOR;
  }

  bytes32 private constant TRANSACTION_TYPEHASH =
    keccak256("Transaction(uint256 txsId,address destination,uint256 value,bytes data)");

  struct Transaction {
    uint256 txsId;
    address destination;
    uint256 value;
    bytes data;
  }

  // computes the hash of a permit
  function getStructHash(Transaction memory transaction_) internal pure returns (bytes32) {
    return keccak256(abi.encode(TRANSACTION_TYPEHASH, transaction_.destination, transaction_.value, transaction_.data));
  }

  // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
  function getTypedDataHash(Transaction memory transaction_) public view returns (bytes32) {
    return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, getStructHash(transaction_)));
  }
}
