// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there are multiple accounts (admins) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict their use to
 * the admins.
 */
contract TeleportAdmin is Ownable {
    mapping(address => bool) private _isAdmin;

    event AdminUpdated(address indexed account, bool indexed status);

    /**
     * @dev Checks if an account is admin.
     */
    function isAdmin(address account) public view returns (bool) {
        return _isAdmin[account];
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "TeleportAdmin: caller is not admin");
        _;
    }

    /**
     * @dev Updates the admin status of an account.
     * Can only be called by the current owner.
     */
    function updateAdmin(address account, bool status) public virtual onlyOwner {
        emit AdminUpdated(account, status);
        _isAdmin[account] = status;
    }
}
