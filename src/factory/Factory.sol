//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Factory {
  using EnumerableSet for *;

  event ContractInstantiation(address sender, address instantiation);

  mapping(address => bool) public isInstantiation;
  mapping(address creater => EnumerableSet.AddressSet) private _instantiations;

  function getInstantiationCount(address creator_) public view returns (uint256) {
    return _instantiations[creator_].values().length;
  }

  function getInstantiations(address creator_) public view returns (address[] memory instantiations) {
    return _instantiations[creator_].values();
  }

  function _register(address instantiation_) internal {
    isInstantiation[instantiation_] = true;
    _instantiations[msg.sender].add(instantiation_);
    emit ContractInstantiation(msg.sender, instantiation_);
  }
}
