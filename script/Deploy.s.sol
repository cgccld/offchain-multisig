// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "./Migrate.s.sol";
import {OffchainMultisig} from "../src/OffchainMultisig.sol";

contract Deploy is BaseMigrate {
  function run() external {
    deploy();
  }

  function deploy() public broadcast {
    address[] memory addresses = new address[](1);
    addresses[0] = 0xB18922995ddE6C185430EfC9DCb79ba86D888Dba;
    deployContract("OffchainMultisig.sol:OffchainMultisig", abi.encode(addresses,1));
  }
}
