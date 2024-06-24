// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "./Migrate.s.sol";
import {OffchainMultisig} from "../src/OffchainMultisig.sol";

contract Deploy is BaseMigrate {
  function run() external {
    deploy();
  }

  function deploy() public broadcast {
    address[] memory addresses = new address[](2);
    addresses[0] = 0x3039f3D6B9997b9878f746feB1C23B00B588569A;
    addresses[1] = 0x7b9e9b3d1AD8Fd0bb2b999877e12dC02B327942B;
    deployContract("OffchainMultisig.sol:OffchainMultisig", abi.encode(addresses, 2));
  }
}
