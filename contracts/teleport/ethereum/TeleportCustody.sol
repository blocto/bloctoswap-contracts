// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./TeleportAdmin.sol";
import "./TetherToken.sol";

/**
 * @dev Implementation of the TeleportCustody contract.
 *
 * There are two priviledged roles for the contract: "owner" and "admin".
 *
 * Owner: Has the ultimate control of the contract and the funds stored inside the
 *        contract. Including:
 *     1) "freeze" and "unfreeze" the contract: when the TeleportCustody is frozen,
 *        all deposits and withdrawals with the TeleportCustody is disabled. This 
 *        should only happen when a major security risk is spotted or if admin access
 *        is comprimised.
 *     2) assign "admins": owner has the authority to grant "unlock" permission to
 *        "admins" and set proper "unlock limit" for each "admin".
 *
 * Admin: Has the authority to "unlock" specific amount to tokens to receivers.
 */
contract TeleportCustody is TeleportAdmin {
  // USDC
  // ERC20 internal _tokenContract = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  
  // USDT
  TetherToken internal _tokenContract = TetherToken(0xdAC17F958D2ee523a2206206994597C13D831ec7);

  // Records that an unlock transaction has been executed
  mapping(bytes32 => bool) internal _unlocked;
  
  // Emmitted when user locks token and initiates teleport
  event Locked(uint256 amount, bytes8 indexed flowAddress, address indexed ethereumAddress);

  // Emmitted when teleport completes and token gets unlocked
  event Unlocked(uint256 amount, address indexed ethereumAddress, bytes32 indexed flowHash);

  /**
    * @dev User locks token and initiates teleport request.
    */
  function lock(uint256 amount, bytes8 flowAddress)
    public
    notFrozen
  {
    address sender = _msgSender();

    // NOTE: Return value should be checked. However, Tether does not have return value.
    _tokenContract.transferFrom(sender, address(this), amount);

    emit Locked(amount, flowAddress, sender);
  }

  // Admin methods

  /**
    * @dev TeleportAdmin unlocks token upon receiving teleport request from Flow.
    */
  function unlock(uint256 amount, address ethereumAddress, bytes32 flowHash)
    public
    notFrozen
    consumeAuthorization(amount)
  {
    _unlock(amount, ethereumAddress, flowHash);
  }

  // Owner methods

  /**
    * @dev Owner unlocks token upon receiving teleport request from Flow.
    * There is no unlock limit for owner.
    */
  function unlockByOwner(uint256 amount, address ethereumAddress, bytes32 flowHash)
    public
    notFrozen
    onlyOwner
  {
    _unlock(amount, ethereumAddress, flowHash);
  }

  // Internal methods

  /**
    * @dev Internal function for processing unlock requests.
    * 
    * There is no way TeleportCustody can check the validity of the target address
    * beforehand so user and admin should always make sure the provided information
    * is correct.
    */
  function _unlock(uint256 amount, address ethereumAddress, bytes32 flowHash)
    internal
  {
    require(ethereumAddress != address(0), "TeleportCustody: ethereumAddress is the zero address");
    require(!_unlocked[flowHash], "TeleportCustody: same unlock hash has been executed");

    _unlocked[flowHash] = true;

    // NOTE: Return value should be checked. However, Tether does not have return value.
    _tokenContract.transfer(ethereumAddress, amount);

    emit Unlocked(amount, ethereumAddress, flowHash);
  }
}
