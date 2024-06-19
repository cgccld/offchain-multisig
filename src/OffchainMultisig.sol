// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { ErrorHandler } from "./libraries/ErrorHandler.sol";
import { UniqueChecker } from "./internal/UniqueChecker.sol";
import { IOffchainMultisig } from "../src/interfaces/IOffchainMultisig.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


contract OffchainMultisig is IOffchainMultisig, EIP712, UniqueChecker {
    uint256 public constant LIMIT_OWNER_REQUIRED = 50;
    bytes32 private constant TRANSACTION_TYPEHASH =
        keccak256("Transaction(address destination,uint256 value,bytes data)");

    using ErrorHandler for *;
    using EnumerableSet for *;

    uint256 public threshold;
    EnumerableSet.AddressSet internal owners;

    /*
     * Modifiers
     */
    modifier selfCallOnly() {
        require(msg.sender == address(this), "Self call only");
        _;
    }

    modifier ownerDoesNotExist(address owner_) {
        require(!owners.contains(owner_), "Owner already existed");
        _;
    }

    modifier ownerExists(address owner_) {
        require(owners.contains(owner_), "Owner does not exists");
        _;
    }

    modifier notNull(address address_) {
        require(address_ != address(0), "Address is null");
        _;
    }

    modifier validRequirement(uint256 ownerCount_, uint256 threshold_) {
        require(
            ownerCount_ <= LIMIT_OWNER_REQUIRED && threshold_ <= ownerCount_ && threshold_ != 0 && ownerCount_ != 0,
            "Not valid requirement"
        );
        _;
    }

    receive() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }

    constructor(
        address[] memory owners_,
        uint256 threshold_
    )
        EIP712("OffchainMultisig", "1")
        validRequirement(owners_.length, threshold_)
    {
        threshold = threshold_;
        for (uint256 i; i < owners_.length;) {
            owners.add(owners_[i]);
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

    /*
     * Keeper only
     */
    function addOwner(address owner_)
        public
        selfCallOnly
        ownerDoesNotExist(owner_)
        notNull(owner_)
        validRequirement(owners.values().length + 1, threshold)
    {
        owners.add(owner_);
        emit OwnerAddition(owner_);
    }

    function removeOwner(address owner_) public selfCallOnly ownerExists(owner_) {
        owners.remove(owner_);
        uint256 length = owners.values().length;
        if (threshold > length) {
            changeRequirement(length);
        }
        emit OwnerRemoval(owner_);
    }

    function replaceOwner(
        address owner_,
        address newOwner_
    )
        public
        selfCallOnly
        ownerExists(owner_)
        ownerDoesNotExist(newOwner_)
    {
        owners.remove(owner_);
        owners.add(newOwner_);
        emit OwnerRemoval(owner_);
        emit OwnerAddition(newOwner_);
    }

    function changeRequirement(uint256 threshold_)
        public
        selfCallOnly
        validRequirement(owners.values().length, threshold_)
    {
        threshold = threshold_;
        emit RequirementChange(threshold_);
    }

    function executeTransaction(
        uint256 transactionId_,
        Transaction calldata transaction_,
        bytes[] memory signatures_
    )
        external
    {
        _setUsed(transactionId_);
        bytes32 digest = _getDigest(transaction_);
        _verify(digest, signatures_);
        _executeTransaction(transactionId_, transaction_);
    }

    function _getDigest(Transaction calldata transaction_) internal view returns (bytes32 digest) {
        bytes32 structHash =
            keccak256(abi.encode(TRANSACTION_TYPEHASH, transaction_.destination, transaction_.value, transaction_.data));
        digest = _hashTypedDataV4(structHash);
    }

    function _isConfirmed(address[] memory confirmedOwners_, address owner_) internal pure returns (bool isConfirmed) {
        for (uint256 i; i < confirmedOwners_.length;) {
            if (confirmedOwners_[i] == owner_) {
                isConfirmed = true;
                break;
            }
            if (confirmedOwners_[i] == address(0)) {
                isConfirmed = false;
                break;
            }
            unchecked {
                ++i;
            }
        }
        return isConfirmed;
    }

    function _verify(bytes32 digest_, bytes[] memory signatures_) internal view {
        address[] memory confirmedOwners = new address[](signatures_.length);
        for (uint256 i; i < signatures_.length;) {
            address signer = ECDSA.recover(digest_, signatures_[i]);
            if (owners.contains(signer)) {
                require(!_isConfirmed(confirmedOwners, signer), "Owner already confirmed");
                confirmedOwners[i] = signer;
            }
            unchecked {
                ++i;
            }
        }
        require(confirmedOwners.length >= threshold, "Threshold not reached");
    }

    function _executeTransaction(uint256 transactionId_, Transaction calldata transaction_) internal {
        (bool success, bytes memory returnOrRevertData) =
            transaction_.destination.call{ value: transaction_.value }(transaction_.data);
        bytes4 callSig = transaction_.data.length >= 4 ? bytes4(transaction_.data[:4]) : bytes4(0);
        success.handleRevert(callSig, returnOrRevertData);
        emit Execution(transactionId_, transaction_.destination, transaction_.value, transaction_.data);
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }
}
