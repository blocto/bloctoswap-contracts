
// File: @openzeppelin/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/teleport/ethereum/Ownable.sol

// SPDX-License-Identifier: MIT
// Modified from github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol

pragma solidity ^0.6.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/teleport/ethereum/TeleportAdmin.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


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

// File: contracts/teleport/ethereum/TetherToken.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract TetherToken {
    function transfer(address _to, uint _value) public {}
    function transferFrom(address _from, address _to, uint _value) public {}
}

// File: contracts/teleport/ethereum/TeleportCustody.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



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
