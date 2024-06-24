// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "./Factory.sol";
import "../OffchainMultisig.sol";

contract OffchainMultisigFactory is Factory {
  function create(address[] memory owners_, uint256 threshold_) public returns (address wallet) {
    wallet = address(new OffchainMultisig(owners_, threshold_));
    _register(wallet);
  }
}
