// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./TeleportAdmin.sol";
import "./TetherToken.sol";

contract TeleportCustody is TeleportAdmin {
  TetherToken private _tokenContract = TetherToken(0xdAC17F958D2ee523a2206206994597C13D831ec7);

  // Emmitted when user locks token and initiates teleport
  event Locked(uint256 amount, bytes8 indexed flowAddress, address indexed ethereumAddress);

  // Emmitted when teleport completes and token gets unlocked
  event Unlocked(uint256 amount, bytes8 indexed flowAddress, address indexed ethereumAddress);

  // Emmitted when token contract is updated
  event TokenContractUpdated(address indexed tokenAddress);

  /**
    * @dev User locks token and initiates teleport request.
    */
  function lock(uint256 amount, bytes8 flowAddress) public {
    address sender = _msgSender();
    _tokenContract.transferFrom(sender, address(this), amount);
    emit Locked(amount, flowAddress, sender);
  }

  /**
    * @dev Admin unlocks token upon receiving teleport request from Flow.
    */
  function unlock(uint256 amount, address ethereumAddress, bytes8 flowAddress) public onlyAdmin {
    require(ethereumAddress != address(0), "TeleportCustody: ethereumAddress is the zero address");
    _tokenContract.transfer(ethereumAddress, amount);
    emit Unlocked(amount, flowAddress, ethereumAddress);
  }

  // Owner methods

  /**
    * @dev Owner withdraws token from lockup contract.
    */
  function withdraw(uint256 amount) public onlyOwner {
    _tokenContract.transfer(owner(), amount);
  }

  /**
    * @dev Owner updates the target lockup token address.
    */
  function updateTokenAddress(address tokenAddress) public onlyOwner {
    _tokenContract = TetherToken(tokenAddress);
  }
}
