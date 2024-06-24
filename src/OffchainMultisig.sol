// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Signable} from "../src/internal/Signable.sol";
import {ErrorHandler} from "./libraries/ErrorHandler.sol";
import {UniqueChecker} from "./internal/UniqueChecker.sol";
import {IOffchainMultisig} from "../src/interfaces/IOffchainMultisig.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract OffchainMultisig is IOffchainMultisig, Signable, UniqueChecker {
  uint256 public constant LIMIT_CRITERIA = 50;
  bytes32 private constant TYPEHASH = 0xb392c21c9ad37d94787e9c7fe4029c1962f3bd164d12a28ace8500a958bbbcf6;

  using ErrorHandler for *;
  using EnumerableSet for *;

  uint256 public threshold;
  EnumerableSet.AddressSet internal owners;

  /*
   * Modifiers
   */
  modifier selfOnly() {

    require(msg.sender == address(this), "SCO");
    _;
  }

  modifier notNull(address addr) {

    require(addr != address(0), "NUL");
    _;
  }

  modifier validRequirement(uint256 ownerSize, uint256 criteria) {
    require(ownerSize <= LIMIT_CRITERIA && criteria <= ownerSize && criteria != 0 && ownerSize != 0, "NVR");
    _;
  }

  receive() external payable {
    if (msg.value > 0) {
      emit Deposit(msg.sender, msg.value);
    }
  }

  constructor(address[] memory initOwners, uint256 criteria)
    Signable("OffchainMultisig", "1")
    validRequirement(initOwners.length, criteria)
  {
    threshold = criteria;
    for (uint256 i; i < initOwners.length;) {
      owners.add(initOwners[i]);
      unchecked {
        ++i;
      }
    }
  }

  /*
   * Read methods
   */
  function getOwners() public view returns (address[] memory) {
    return owners.values();
  }

  function addOwner(address owner)
    public
    selfOnly
    notNull(owner)
    validRequirement(owners.values().length + 1, threshold)
  {
    require(owners.add(owner), "OAE");
    emit OwnerAddition(owner);
  }

  function removeOwner(address owner) public selfOnly {
    require(owners.remove(owner), "ONE");
    uint256 length = owners.values().length;
    if (threshold > length) {
      changeRequirement(length);
    }
    emit OwnerRemoval(owner);
  }

  function replaceOwner(address owner, address newOwner) public selfOnly {
    require(owners.remove(owner) && owners.add(newOwner), "WPA");
    emit OwnerRemoval(owner);
    emit OwnerAddition(newOwner);
  }

  function changeRequirement(uint256 criteria) public selfOnly validRequirement(owners.values().length, criteria) {
    threshold = criteria;
    emit RequirementChange(criteria);
  }

  function executeTransaction(uint256 txsId, Transaction calldata txs, bytes[] memory signatures) external {
    _setUsed(txsId);
    _verify(txs, signatures);
    _execute(txsId, txs);
  }

  function alreadyConfirmed(address[] memory confirmed, address owner) internal pure returns (bool isConfirmed) {
    for (uint256 i; i < confirmed.length;) {
      if (confirmed[i] == owner) {
        isConfirmed = true;
        break;
      }
      if (confirmed[i] == address(0)) {
        isConfirmed = false;
        break;
      }
      unchecked {
        ++i;
      }
    }
    return isConfirmed;
  }

  function _verify(Transaction calldata txs, bytes[] memory signatures) internal view {
    uint256 len = signatures.length;
    address[] memory confirmed = new address[](len);

    bytes32 structHash = keccak256(abi.encode(TYPEHASH, txs.destination, txs.value, txs.data));

    for (uint256 i; i < len;) {
      address signer = _recoverSigner(structHash, signatures[i]);
      if (owners.contains(signer)) {
        require(!alreadyConfirmed(confirmed, signer), "Owner already confirmed");
        confirmed[i] = signer;
      }
      unchecked {
        ++i;
      }
    }

    require(confirmed.length >= threshold, "Threshold not reached");
  }

  function _execute(uint256 txsId, Transaction calldata txs) internal {
    address dest = txs.destination;
    uint256 value = txs.value;
    bytes memory data = txs.data;

    (bool success, bytes memory retData) = dest.call{value: value}(data);

    bytes4 callSig = data.length >= 4 ? bytes4(txs.data[:4]) : bytes4(0);
    success.handleRevert(callSig, retData);

    emit Execution(txsId, dest, value, data);
  }
}
