// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./TeleportCustody.sol";
import "./TetherToken.sol";

contract TeleportCustodyTest is TeleportCustody {
  constructor(address tetherTokenAddress) 
    public
  {
    _tokenContract = TetherToken(tetherTokenAddress);
  }
}
