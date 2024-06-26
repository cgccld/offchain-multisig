// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Signable} from "../src/internal/Signable.sol";
import {ErrorHandler} from "./libraries/ErrorHandler.sol";
import {UniqueChecker} from "./internal/UniqueChecker.sol";
import {IOffchainMultisig} from "../src/interfaces/IOffchainMultisig.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract OffchainMultisig is IOffchainMultisig, Signable, UniqueChecker {
  uint256 public constant LIMIT_CRITERIA = 50;
  bytes32 private constant TYPEHASH =
    keccak256("Transaction(uint256 txsId,address destination,uint256 value,bytes data)");

  using ErrorHandler for *;
  using EnumerableSet for *;

  uint256 public criteria;
  EnumerableSet.AddressSet internal owners;

  /*
     * Modifiers
     */
  modifier onlySelf() {
    if (msg.sender != address(this)) {
      revert OnlySelf();
    }
    _;
  }

  modifier notNull(address addr) {
    if (addr == address(0)) {
      revert InvalidAddress();
    }
    _;
  }

  modifier validRequirement(uint256 ownerSize, uint256 crit) {
    if (ownerSize > LIMIT_CRITERIA || crit > ownerSize || crit == 0 || ownerSize == 0) {
      revert InvalidRequirement();
    }
    _;
  }

  receive() external payable {
    if (msg.value > 0) {
      emit Deposit(msg.sender, msg.value);
    }
  }

  constructor(address[] memory initOwners, uint256 crit)
    Signable("OffchainMultisig", "1")
    validRequirement(initOwners.length, crit)
  {
    criteria = crit;
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
    onlySelf
    notNull(owner)
    validRequirement(owners.values().length + 1, criteria)
  {
    if (!owners.add(owner)) {
      revert OwnerAlreadyExisted(owner);
    }
    emit OwnerAddition(owner);
  }

  function removeOwner(address owner) public onlySelf {
    if (!owners.remove(owner)) {
      revert OwnerDoesNotExist(owner);
    }
    uint256 length = owners.values().length;
    if (criteria > length) {
      changeRequirement(length);
    }
    emit OwnerRemoval(owner);
  }

  function replaceOwner(address owner, address newOwner) public onlySelf {
    if (!(owners.remove(owner) && owners.add(newOwner))) {
      revert WrongPositionAddress();
    }

    emit OwnerRemoval(owner);
    emit OwnerAddition(newOwner);
  }

  function changeRequirement(uint256 crit) public onlySelf validRequirement(owners.values().length, crit) {
    criteria = crit;
    emit RequirementChange(crit);
  }

  function executeTransaction(uint256 txsId, Transaction calldata txs, bytes[] memory signatures) external {
    _setUsed(txsId);
    _verify(txsId, txs, signatures);
    _execute(txsId, txs);
  }

  function _alreadyConfirmed(address[] memory confirmed, address owner) internal pure returns (bool isConfirmed) {
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

  function _verify(uint256 txsId, Transaction calldata txs, bytes[] memory signatures) internal view {
    uint256 len = signatures.length;

    if (len < criteria) {
      revert NotMetCriteria(criteria, len);
    }

    address[] memory confirmed = new address[](len);

    bytes32 structHash = keccak256(abi.encode(TYPEHASH, txsId, txs.destination, txs.value, txs.data));

    for (uint256 i; i < len;) {
      address signer = _recoverSigner(structHash, signatures[i]);
      if (owners.contains(signer)) {
        if (_alreadyConfirmed(confirmed, signer)) {
          revert OwnerAlreadyConfirmed(signer);
        }
        confirmed[i] = signer;
      }
      unchecked {
        ++i;
      }
    }
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
