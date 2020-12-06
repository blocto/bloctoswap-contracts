// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there are multiple accounts (admins) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `consumeAuthorization`, which can be applied to your functions to restrict
 * their use to the admins.
 */
contract TeleportAdmin is Ownable {
  mapping(address => uint256) private _allowedAmount;

  event AdminUpdated(address indexed account, uint256 allowedAmount);

  /**
    * @dev Checks the authorized amount of an admin account.
    */
  function allowedAmount(address account) public view returns (uint256) {
    return _allowedAmount[account];
  }

  /**
    * @dev Throw if caller does not have sufficient authorized amount.
    */
  modifier consumeAuthorization(uint256 amount) {
    address sender = _msgSender();
    require(
      allowedAmount(sender) >= amount,
      "TeleportAdmin: caller does not have sufficient authorization"
    );

    _;

    // reduce authorization amount
    _allowedAmount[sender] -= amount;
    emit AdminUpdated(sender, _allowedAmount[sender]);
  }

  /**
    * @dev Updates the admin status of an account.
    * Can only be called by the current owner.
    */
  function updateAdmin(address account, uint256 allowedAmount) public virtual onlyOwner {
    emit AdminUpdated(account, allowedAmount);
    _allowedAmount[account] = allowedAmount;
  }
}
