// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

abstract contract Signable is Nonces, EIP712 {
  using ECDSA for bytes32;

  error InvalidSignature();

  constructor(string memory name_, string memory version_) EIP712(name_, version_) {}

  function _verify(address verifier, bytes32 structHash, bytes memory signature) internal view virtual {
    if (_recoverSigner(structHash, signature) != verifier) {
      revert InvalidSignature();
    }
  }

  function _verify(address verifier, bytes32 structHash, uint8 v, bytes32 r, bytes32 s) internal view virtual {
    if (_recoverSigner(structHash, v, r, s) != verifier) {
      revert InvalidSignature();
    }
  }

  function _recoverSigner(bytes32 structHash, bytes memory signature) internal view returns (address signer) {
    return _hashTypedDataV4(structHash).recover(signature);
  }

  function _recoverSigner(bytes32 structHash, uint8 v, bytes32 r, bytes32 s) internal view returns (address signer) {
    return _hashTypedDataV4(structHash).recover(v, r, s);
  }

  function nonces(address owner) public view virtual override(Nonces) returns (uint256) {
    return super.nonces(owner);
  }

  function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
    return _domainSeparatorV4();
  }
}
