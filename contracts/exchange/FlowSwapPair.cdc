import FungibleToken from 0xFUNGIBLETOKENADDRESS
import FlowToken from 0xFLOWTOKENADDRESS
import TeleportedTetherToken from 0xTELEPORTEDTETHERTOKENADDRESS

// Exchange pair between FlowToken and TeleportedTetherToken
// Token1: FlowToken
// Token2: TeleportedTetherToken
pub contract FlowSwapPair: FungibleToken {
  // Total supply of FlowSwapExchange liquidity token in existence
  pub var totalSupply: UFix64

  // Fee charged when performing token swap
  pub var feePercentage: UFix64

  // Controls FlowToken vault
  access(contract) let token1VaultRef: &FlowToken.Vault

  // Controls TeleportedTetherToken vault
  access(contract) let token2VaultRef: &TeleportedTetherToken.Vault

  // // Defines token vault storage path
  // pub let TokenStoragePath: Path

  // // Defines token vault public balance path
  // pub let TokenPublicBalancePath: Path

  // // Defines token vault public receiver path
  // pub let TokenPublicReceiverPath: Path

  // Event that is emitted when the contract is created
  pub event TokensInitialized(initialSupply: UFix64)

  // Event that is emitted when tokens are withdrawn from a Vault
  pub event TokensWithdrawn(amount: UFix64, from: Address?)

  // Event that is emitted when tokens are deposited to a Vault
  pub event TokensDeposited(amount: UFix64, to: Address?)

  // Event that is emitted when new tokens are minted
  pub event TokensMinted(amount: UFix64)

  // Event that is emitted when tokens are destroyed
  pub event TokensBurned(amount: UFix64)

  // Vault
  //
  // Each user stores an instance of only the Vault in their storage
  // The functions in the Vault and governed by the pre and post conditions
  // in FlowSwapExchange when they are called.
  // The checks happen at runtime whenever a function is called.
  //
  // Resources can only be created in the context of the contract that they
  // are defined in, so there is no way for a malicious user to create Vaults
  // out of thin air. A special Minter resource needs to be defined to mint
  // new tokens.
  //
  pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {

    // holds the balance of a users tokens
    pub var balance: UFix64

    // initialize the balance at resource creation time
    init(balance: UFix64) {
      self.balance = balance
    }

    // withdraw
    //
    // Function that takes an integer amount as an argument
    // and withdraws that amount from the Vault.
    // It creates a new temporary Vault that is used to hold
    // the money that is being transferred. It returns the newly
    // created Vault to the context that called so it can be deposited
    // elsewhere.
    //
    pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
      self.balance = self.balance - amount
      emit TokensWithdrawn(amount: amount, from: self.owner?.address)
      return <-create Vault(balance: amount)
    }

    // deposit
    //
    // Function that takes a Vault object as an argument and adds
    // its balance to the balance of the owners Vault.
    // It is allowed to destroy the sent Vault because the Vault
    // was a temporary holder of the tokens. The Vault's balance has
    // been consumed and therefore can be destroyed.
    pub fun deposit(from: @FungibleToken.Vault) {
      let vault <- from as! @FlowSwapPair.Vault
      self.balance = self.balance + vault.balance
      emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
      vault.balance = 0.0
      destroy vault
    }

    destroy() {
      FlowSwapPair.totalSupply = FlowSwapPair.totalSupply - self.balance
    }
  }

  // createEmptyVault
  //
  // Function that creates a new Vault with a balance of zero
  // and returns it to the calling context. A user must call this function
  // and store the returned Vault in their storage in order to allow their
  // account to be able to receive deposits of this token type.
  //
  pub fun createEmptyVault(): @FungibleToken.Vault {
    return <-create Vault(balance: 0.0)
  }

  pub resource TokenBundle {
    pub var token1: @FlowToken.Vault
    pub var token2: @TeleportedTetherToken.Vault

    // initialize the vault bundle
    init(fromToken1: @FlowToken.Vault, fromToken2: @TeleportedTetherToken.Vault) {
      self.token1 <- fromToken1
      self.token2 <- fromToken2
    }

    pub fun depositToken1(from: @FlowToken.Vault) {
      self.token1.deposit(from: <- (from as! @FungibleToken.Vault))
    }

    pub fun depositToken2(from: @TeleportedTetherToken.Vault) {
      self.token2.deposit(from: <- (from as! @FungibleToken.Vault))
    }

    pub fun withdrawToken1(): @FlowToken.Vault {
      var vault <- FlowToken.createEmptyVault() as! @FlowToken.Vault
      vault <-> self.token1
      return <- vault
    }

    pub fun withdrawToken2(): @TeleportedTetherToken.Vault {
      var vault <- TeleportedTetherToken.createEmptyVault() as! @TeleportedTetherToken.Vault
      vault <-> self.token2
      return <- vault
    }

    destroy() {
      destroy self.token1
      destroy self.token2
    }
  }

  // createEmptyTokenBundle
  //
  pub fun createEmptyTokenBundle(): @FlowSwapPair.TokenBundle {
    return <- create TokenBundle(
      fromToken1: <- (FlowToken.createEmptyVault() as! @FlowToken.Vault),
      fromToken2: <- (TeleportedTetherToken.createEmptyVault() as! @TeleportedTetherToken.Vault)
    )
  }

  // createTokenBundle
  //
  pub fun createTokenBundle(fromToken1: @FlowToken.Vault, fromToken2: @TeleportedTetherToken.Vault): @FlowSwapPair.TokenBundle {
    return <- create TokenBundle(fromToken1: <- fromToken1, fromToken2: <- fromToken2)
  }

  // mintTokens
  //
  // Function that mints new tokens, adds them to the total supply,
  // and returns them to the calling context.
  //
  access(contract) fun mintTokens(amount: UFix64): @FlowSwapPair.Vault {
    pre {
      amount > UFix64(0): "Amount minted must be greater than zero"
    }
    FlowSwapPair.totalSupply = FlowSwapPair.totalSupply + amount
    emit TokensMinted(amount: amount)
    return <-create Vault(balance: amount)
  }

  // burnTokens
  //
  // Function that destroys a Vault instance, effectively burning the tokens.
  //
  // Note: the burned tokens are automatically subtracted from the 
  // total supply in the Vault destructor.
  //
  access(contract) fun burnTokens(from: @FlowSwapPair.Vault) {
    let vault <- from as! @FlowSwapPair.Vault
    let amount = vault.balance
    destroy vault
    emit TokensBurned(amount: amount)
  }

  pub resource Admin {
    pub fun addInitialLiquidity(from: @FlowSwapPair.TokenBundle): @FlowSwapPair.Vault {
      pre {
        FlowSwapPair.totalSupply == UFix64(0): "Pair already initialized"
      }

      let token1Vault <- from.withdrawToken1()
      let token2Vault <- from.withdrawToken2()

      assert(token1Vault.balance > UFix64(0), message: "Empty token1 vault")
      assert(token2Vault.balance > UFix64(0), message: "Empty token2 vault")

      FlowSwapPair.token1VaultRef.deposit(from: <- token1Vault)
      FlowSwapPair.token2VaultRef.deposit(from: <- token2Vault)

      destroy from

      // Create initial tokens
      return <- FlowSwapPair.mintTokens(amount: 1.0)
    }

    pub fun updateFeePercentage(feePercentage: UFix64) {
      FlowSwapPair.feePercentage = feePercentage
    }
  }

  pub fun swapToken1ForToken2(from: @FlowToken.Vault): @TeleportedTetherToken.Vault {
    self.token1VaultRef.deposit(from: <- (from as! @FungibleToken.Vault))

    return <- (TeleportedTetherToken.createEmptyVault() as! @TeleportedTetherToken.Vault)
  }

  pub fun swapToken2ForToken1(from: @TeleportedTetherToken.Vault): @FlowToken.Vault {
    self.token2VaultRef.deposit(from: <- (from as! @FungibleToken.Vault))

    return <- (FlowToken.createEmptyVault() as! @FlowToken.Vault)
  }

  pub fun addLiquidity(from: @FlowSwapPair.TokenBundle): @FlowSwapPair.Vault {
    pre {
      self.totalSupply > UFix64(0): "Pair must be initialized by admin first"
    }

    let token1Vault <- from.withdrawToken1()
    let token2Vault <- from.withdrawToken2()

    assert(token1Vault.balance > UFix64(0), message: "Empty token1 vault")
    assert(token2Vault.balance > UFix64(0), message: "Empty token2 vault")

    FlowSwapPair.token1VaultRef.deposit(from: <- token1Vault)
    FlowSwapPair.token2VaultRef.deposit(from: <- token2Vault)

    destroy from
    return <- (FlowSwapPair.createEmptyVault() as! @FlowSwapPair.Vault)
  }

  pub fun removeLiquidity(from: @FlowSwapPair.Vault): @FlowSwapPair.TokenBundle {
    destroy from
    return <- FlowSwapPair.createEmptyTokenBundle()
  }

  init() {
    self.totalSupply = 0.0
    self.feePercentage = 0.005
    // self.TokenStoragePath = /storage/teleportedTetherTokenVault
    // self.TokenPublicBalancePath = /public/teleportedTetherTokenBalance
    // self.TokenPublicReceiverPath = /public/teleportedTetherTokenReceiver

    let token1Vault <- FlowToken.createEmptyVault() as! @FlowToken.Vault
    self.account.save(<-token1Vault, to: /storage/flowTokenVault)

    // Expose public receiver reference
    self.account.link<&FlowToken.Vault{FungibleToken.Receiver}>(
      /public/flowTokenReceiver,
      target: /storage/flowTokenVault
    )

    // Expose public balance reference
    self.account.link<&FlowToken.Vault{FungibleToken.Balance}>(
      /public/flowTokenBalance,
      target: /storage/flowTokenVault
    )

    self.token1VaultRef = self.account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
      ?? panic("Could not borrow capability to FlowToken vault")

    let token2Vault <- TeleportedTetherToken.createEmptyVault() as! @TeleportedTetherToken.Vault
    self.account.save(<-token2Vault, to: /storage/teleportedTetherTokenVault)

    // Expose public receiver reference
    self.account.link<&TeleportedTetherToken.Vault{FungibleToken.Receiver}>(
      /public/teleportedTetherTokenReceiver,
      target: /storage/teleportedTetherTokenVault
    )

    // Expose public balance reference
    self.account.link<&TeleportedTetherToken.Vault{FungibleToken.Balance}>(
      /public/teleportedTetherTokenBalance,
      target: /storage/teleportedTetherTokenVault
    )

    self.token2VaultRef = self.account.borrow<&TeleportedTetherToken.Vault>(from: /storage/teleportedTetherTokenVault)
      ?? panic("Could not borrow capability to TeleportedTetherToken vault")

    let admin <- create Admin()
    self.account.save(<-admin, to: /storage/flowSwapPairAdmin)

    // Emit an event that shows that the contract was initialized
    emit TokensInitialized(initialSupply: self.totalSupply)
  }
}
