// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./TeleportAdmin.sol";
import "./TetherToken.sol";

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
  {
    address sender = _msgSender();
    _tokenContract.transferFrom(sender, address(this), amount);
    emit Locked(amount, flowAddress, sender);
  }

  /**
    * @dev Internal function for processing unlock requests.
    */
  function _unlock(uint256 amount, address ethereumAddress, bytes32 flowHash)
    internal
  {
    require(ethereumAddress != address(0), "TeleportCustody: ethereumAddress is the zero address");
    require(!_unlocked[flowHash], "TeleportCustody: same unlock hash has been executed");

    _unlocked[flowHash] = true;
    _tokenContract.transfer(ethereumAddress, amount);

    emit Unlocked(amount, ethereumAddress, flowHash);
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
    onlyOwner
  {
    _unlock(amount, ethereumAddress, flowHash);
  }
}
