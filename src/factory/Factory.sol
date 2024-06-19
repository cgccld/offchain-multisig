pragma solidity 0.8.25;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Factory {
    using EnumerableSet for *;
    /*
     *  Events
     */

    event ContractInstantiation(address sender, address instantiation);

    /*
     *  Storage
     */
    mapping(address => bool) public isInstantiation;
    mapping(address creater => EnumerableSet.AddressSet) private _instantiations;

    /*
     * Public functions
     */
    function getInstantiationCount(address creator_) public view returns (uint256) {
        return _instantiations[creator_].values().length;
    }

    function getInstantiations(address creator_) public view returns (address[] memory instantiations) {
        return _instantiations[creator_].values();
    }

    /*
     * Internal functions
     */
    function _register(address instantiation_) internal {
        isInstantiation[instantiation_] = true;
        _instantiations[msg.sender].add(instantiation_);
        emit ContractInstantiation(msg.sender, instantiation_);
    }
}
