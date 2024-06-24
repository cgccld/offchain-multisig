// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
  constructor() ERC20("MockERC20", "M20") {}

  function mint(address to, uint256 value) public {
    _mint(to, value);
  }

  function burn(uint256 value) public {
    _burn(_msgSender(), value);
  }
}
