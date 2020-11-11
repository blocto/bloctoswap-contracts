// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./TeleportAdmin.sol";
import "./TetherToken.sol";

contract TeleportCustody is TeleportAdmin {
  address private _tokenAddress;

  TetherToken private _tokenContract;

  // Emmitted when user locks token and initiates teleport
  event Locked(uint256 amount, bytes8 indexed flowAddress, address indexed ethereumAddress);

  // Emmitted when teleport completes and token gets unlocked
  event Unlocked(uint256 amount, bytes8 indexed flowAddress, address indexed ethereumAddress);

  function lock(uint256 amount, bytes8 flowAddress) public {
    address sender = _msgSender();
    _tokenContract.transferFrom(sender, address(this), amount);
    emit Locked(amount, flowAddress, sender);
  }

  function unlock(uint256 amount, address ethereumAddress, bytes8 flowAddress) public onlyAdmin {
    require(ethereumAddress != address(0), "TeleportCustody: ethereumAddress is the zero address");
    _tokenContract.transfer(ethereumAddress, amount);
    emit Unlocked(amount, flowAddress, ethereumAddress);
  }

  // Owner methods
  function withdraw(uint256 amount) public onlyOwner {
    _tokenContract.transfer(owner(), amount);
  }

  function updateTokenAddress(address tokenAddress) public onlyOwner {
    _tokenAddress = tokenAddress;
    _tokenContract = TetherToken(tokenAddress);
  }
}
