// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

abstract contract UniqueChecker {
  using BitMaps for BitMaps.BitMap;

  error AlreadyUsed(uint256);

  BitMaps.BitMap private _isUsed;

  function _setUsed(uint256 uid) internal {
    if (_isUsed.get(uid)) revert AlreadyUsed(uid);
    _isUsed.set(uid);
  }

  function _used(uint256 uid) internal view returns (bool) {
    return _isUsed.get(uid);
  }

  function isValid(uint256 uid) public view returns (bool) {
    return _isUsed.get(uid);
  }
}
