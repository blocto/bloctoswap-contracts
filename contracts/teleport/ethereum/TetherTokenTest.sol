// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./TetherToken.sol";

/**
 * @dev Method signature contract for Tether (USDT) because it's not a standard
 * ERC-20 contract and have different method signatures.
 */
contract TetherTokenTest is TetherToken {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function transfer(address _to, uint _value)
    override
    public
  {
    emit Transfer(msg.sender, _to, _value);
  }

  function transferFrom(address _from, address _to, uint _value)
    override
    public
  {
    emit Transfer(_from, _to, _value);
  }
}
