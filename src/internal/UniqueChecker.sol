// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

abstract contract UniqueChecker {
    using BitMaps for BitMaps.BitMap;

    error TransactionIdAlreadyUsed();

    BitMaps.BitMap private _isUsed;

    function _setUsed(uint256 txnId_) internal {
        if (_isUsed.get(txnId_)) revert TransactionIdAlreadyUsed();
        _isUsed.set(txnId_);
    }

    function _used(uint256 txnId_) internal view returns (bool) {
        return _isUsed.get(txnId_);
    }

    function isTransactionIdValid(uint256 txnId_) public view returns (bool) {
        return _isUsed.get(txnId_);
    }

    uint256[49] private __gap;
}
