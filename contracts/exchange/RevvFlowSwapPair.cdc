import "Burner"
import "FungibleToken"
import "REVV"
import "FlowToken"
import "MetadataViews"
import "FungibleTokenMetadataViews"

// Exchange pair between REVV and FlowToken
// Token1: REVV
// Token2: FlowToken
access(all) contract RevvFlowSwapPair: FungibleToken {
  // Frozen flag controlled by Admin
  access(all) var isFrozen: Bool
  
  // Total supply of RevvFlowSwapPair liquidity token in existence
  access(all) var totalSupply: UFix64

  // Fee charged when performing token swap
  access(all) var feePercentage: UFix64

  // Controls REVV vault
  access(contract) let token1Vault: @REVV.Vault

  // Controls FlowToken vault
  access(contract) let token2Vault: @FlowToken.Vault

  // Defines token vault storage path
  access(all) let TokenStoragePath: StoragePath

  // Defines token vault public balance path
  access(all) let TokenPublicBalancePath: PublicPath

  // Defines token vault public receiver path
  access(all) let TokenPublicReceiverPath: PublicPath

  // Event that is emitted when the contract is created
  access(all) event TokensInitialized(initialSupply: UFix64)

  // Event that is emitted when tokens are withdrawn from a Vault
  access(all) event TokensWithdrawn(amount: UFix64, from: Address?)

  // Event that is emitted when tokens are deposited to a Vault
  access(all) event TokensDeposited(amount: UFix64, to: Address?)

  // Event that is emitted when new tokens are minted
  access(all) event TokensMinted(amount: UFix64)

  // Event that is emitted when tokens are destroyed
  access(all) event TokensBurned(amount: UFix64)

  // Event that is emitted when trading fee is updated
  access(all) event FeeUpdated(feePercentage: UFix64)

  // Event that is emitted when a swap happens
  // Side 1: from token1 to token2
  // Side 2: from token2 to token1
  access(all) event Trade(token1Amount: UFix64, token2Amount: UFix64, side: UInt8)

  /// Gets a list of the metadata views that this contract supports
  access(all) view fun getContractViews(resourceType: Type?): [Type] {
    return [Type<FungibleTokenMetadataViews.FTView>(),
            Type<FungibleTokenMetadataViews.FTDisplay>(),
            Type<FungibleTokenMetadataViews.FTVaultData>(),
            Type<FungibleTokenMetadataViews.TotalSupply>()]
  }

  /// Get a Metadata View
  ///
  /// @param view: The Type of the desired view.
  /// @return A structure representing the requested view.
  ///
  access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
    switch viewType {
      case Type<FungibleTokenMetadataViews.FTView>():
        return FungibleTokenMetadataViews.FTView(
          ftDisplay: self.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTDisplay>()) as! FungibleTokenMetadataViews.FTDisplay?,
          ftVaultData: self.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTVaultData>()) as! FungibleTokenMetadataViews.FTVaultData?
        )
      case Type<FungibleTokenMetadataViews.FTDisplay>():
        let media = MetadataViews.Media(
            file: MetadataViews.HTTPFile(
            url: "https://swap.blocto.app/favicon-144x144.png"
          ),
          mediaType: "image/png"
        )
        let medias = MetadataViews.Medias([media])
        return FungibleTokenMetadataViews.FTDisplay(
          name: "REVV/FLOW Swap LP Token",
          symbol: "REVVFLOW",
          description: "BloctoSwap liquidity provider token for the REVV/FLOW swap pair.",
          externalURL: MetadataViews.ExternalURL("https://swap.blocto.app"),
          logos: medias,
          socials: {
            "twitter": MetadataViews.ExternalURL("https://x.com/bloctoapp")
          }
        )
      case Type<FungibleTokenMetadataViews.FTVaultData>():
        let vaultRef = RevvFlowSwapPair.account.storage.borrow<auth(FungibleToken.Withdraw) &RevvFlowSwapPair.Vault>(from: /storage/revvFlowSwapLpVault)
        ?? panic("Could not borrow reference to the contract's Vault!")
          return FungibleTokenMetadataViews.FTVaultData(
            storagePath: /storage/revvFlowSwapLpVault,
            receiverPath: /public/revvFlowSwapLpReceiver,
            metadataPath: /public/revvFlowSwapLpBalance,
            receiverLinkedType: Type<&{FungibleToken.Receiver, FungibleToken.Vault}>(),
            metadataLinkedType: Type<&{FungibleToken.Balance, FungibleToken.Vault}>(),
            createEmptyVaultFunction: (fun (): @{FungibleToken.Vault} {
              return <-vaultRef.createEmptyVault()
            })
          )
      case Type<FungibleTokenMetadataViews.TotalSupply>():
          return FungibleTokenMetadataViews.TotalSupply(totalSupply: RevvFlowSwapPair.totalSupply)
    }
    return nil
  }

  // Vault
  //
  // Each user stores an instance of only the Vault in their storage
  // The functions in the Vault and governed by the pre and post conditions
  // in RevvFlowSwapPair when they are called.
  // The checks happen at runtime whenever a function is called.
  //
  // Resources can only be created in the context of the contract that they
  // are defined in, so there is no way for a malicious user to create Vaults
  // out of thin air. A special Minter resource needs to be defined to mint
  // new tokens.
  //
  access(all) resource Vault: FungibleToken.Vault {

    // holds the balance of a users tokens
    access(all) var balance: UFix64

    // initialize the balance at resource creation time
    init(balance: UFix64) {
      self.balance = balance
    }

    // Called when a fungible token is burned via the `Burner.burn()` method
    access(contract) fun burnCallback() {
      if self.balance > 0.0 {
        RevvFlowSwapPair.totalSupply = RevvFlowSwapPair.totalSupply - self.balance
      }
      self.balance = 0.0
    }

    // getSupportedVaultTypes optionally returns a list of vault types that this receiver accepts
    access(all) view fun getSupportedVaultTypes(): {Type: Bool} {
      return {self.getType(): true}
    }

    access(all) view fun isSupportedVaultType(type: Type): Bool {
      if (type == self.getType()) { return true } else { return false }
    }
    
    access(all) view fun isAvailableToWithdraw(amount: UFix64): Bool{ 
      return self.balance >= amount
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
    access(FungibleToken.Withdraw) fun withdraw(amount: UFix64): @{FungibleToken.Vault} {
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
    access(all) fun deposit(from: @{FungibleToken.Vault}) {
      let vault <- from as! @RevvFlowSwapPair.Vault
      self.balance = self.balance + vault.balance
      emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
      vault.balance = 0.0
      destroy vault
    }

    // Get all the Metadata Views implemented
    //
    // @return An array of Types defining the implemented views. This value will be used by
    //         developers to know which parameter to pass to the resolveView() method.
    //
    access(all) view fun getViews(): [Type]{
        return RevvFlowSwapPair.getContractViews(resourceType: nil)
    }

    // Get a Metadata View
    //
    // @param view: The Type of the desired view.
    // @return A structure representing the requested view.
    //
    access(all) fun resolveView(_ view: Type): AnyStruct? {
        return RevvFlowSwapPair.resolveContractView(resourceType: nil, viewType: view)
    }

    access(all) fun createEmptyVault(): @{FungibleToken.Vault}{ 
      return <-create Vault(balance: 0.0)
    }
  }

  // createEmptyVault
  //
  // Function that creates a new Vault with a balance of zero
  // and returns it to the calling context. A user must call this function
  // and store the returned Vault in their storage in order to allow their
  // account to be able to receive deposits of this token type.
  //
  access(all) fun createEmptyVault(vaultType: Type): @RevvFlowSwapPair.Vault {
    return <-create Vault(balance: 0.0)
  }

  access(all) resource TokenBundle {
    access(all) var token1: @REVV.Vault
    access(all) var token2: @FlowToken.Vault

    // initialize the vault bundle
    init(fromToken1: @REVV.Vault, fromToken2: @FlowToken.Vault) {
      self.token1 <- fromToken1
      self.token2 <- fromToken2
    }

    access(all) fun depositToken1(from: @REVV.Vault) {
      self.token1.deposit(from: <- (from as! @{FungibleToken.Vault}))
    }

    access(all) fun depositToken2(from: @FlowToken.Vault) {
      self.token2.deposit(from: <- (from as! @{FungibleToken.Vault}))
    }

    access(all) fun withdrawToken1(): @REVV.Vault {
      var vault <- REVV.createEmptyVault(vaultType: Type<@REVV.Vault>())
      vault <-> self.token1
      return <- vault
    }

    access(all) fun withdrawToken2(): @FlowToken.Vault {
      var vault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
      vault <-> self.token2
      return <- vault
    }
  }

  // createEmptyBundle
  //
  access(all) fun createEmptyTokenBundle(): @RevvFlowSwapPair.TokenBundle {
    return <- create TokenBundle(
      fromToken1: <- REVV.createEmptyVault(vaultType: Type<@REVV.Vault>()),
      fromToken2: <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
    )
  }

  // createTokenBundle
  //
  access(all) fun createTokenBundle(fromToken1: @REVV.Vault, fromToken2: @FlowToken.Vault): @RevvFlowSwapPair.TokenBundle {
    return <- create TokenBundle(fromToken1: <- fromToken1, fromToken2: <- fromToken2)
  }

  // mintTokens
  //
  // Function that mints new tokens, adds them to the total supply,
  // and returns them to the calling context.
  //
  access(contract) fun mintTokens(amount: UFix64): @RevvFlowSwapPair.Vault {
    pre {
      amount > 0.0: "Amount minted must be greater than zero"
    }
    RevvFlowSwapPair.totalSupply = RevvFlowSwapPair.totalSupply + amount
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
  access(contract) fun burnTokens(from: @RevvFlowSwapPair.Vault) {
    let vault <- from as! @RevvFlowSwapPair.Vault
    let amount = vault.balance
    Burner.burn(<- vault)
    emit TokensBurned(amount: amount)
  }

  access(all) resource Admin {
    access(all) fun freeze() {
      RevvFlowSwapPair.isFrozen = true
    }

    access(all) fun unfreeze() {
      RevvFlowSwapPair.isFrozen = false
    }

    access(all) fun addInitialLiquidity(from: @RevvFlowSwapPair.TokenBundle): @RevvFlowSwapPair.Vault {
      pre {
        RevvFlowSwapPair.totalSupply == 0.0: "Pair already initialized"
      }

      let token1Vault <- from.withdrawToken1()
      let token2Vault <- from.withdrawToken2()

      assert(token1Vault.balance > 0.0, message: "Empty token1 vault")
      assert(token2Vault.balance > 0.0, message: "Empty token2 vault")

      RevvFlowSwapPair.token1Vault.deposit(from: <- token1Vault)
      RevvFlowSwapPair.token2Vault.deposit(from: <- token2Vault)

      destroy from

      // Create initial tokens
      return <- RevvFlowSwapPair.mintTokens(amount: 1.0)
    }

    access(all) fun updateFeePercentage(feePercentage: UFix64) {
      RevvFlowSwapPair.feePercentage = feePercentage

      emit FeeUpdated(feePercentage: feePercentage)
    }
  }

  access(all) struct PoolAmounts {
    access(all) let token1Amount: UFix64
    access(all) let token2Amount: UFix64

    init(token1Amount: UFix64, token2Amount: UFix64) {
      self.token1Amount = token1Amount
      self.token2Amount = token2Amount
    }
  }

  access(all) fun getFeePercentage(): UFix64 {
    return self.feePercentage
  }

  // Check current pool amounts
  access(all) fun getPoolAmounts(): PoolAmounts {
    return PoolAmounts(token1Amount: RevvFlowSwapPair.token1Vault.balance, token2Amount: RevvFlowSwapPair.token2Vault.balance)
  }

  // Get quote for Token1 (given) -> Token2
  access(all) fun quoteSwapExactToken1ForToken2(amount: UFix64): UFix64 {
    let poolAmounts = self.getPoolAmounts()

    // token1Amount * token2Amount = token1Amount' * token2Amount' = (token1Amount + amount) * (token2Amount - quote)
    let quote = poolAmounts.token2Amount * amount / (poolAmounts.token1Amount + amount);

    return quote
  }

  // Get quote for Token1 -> Token2 (given)
  access(all) fun quoteSwapToken1ForExactToken2(amount: UFix64): UFix64 {
    let poolAmounts = self.getPoolAmounts()

    assert(poolAmounts.token2Amount > amount, message: "Not enough Token2 in the pool")

    // token1Amount * token2Amount = token1Amount' * token2Amount' = (token1Amount + quote) * (token2Amount - amount)
    let quote = poolAmounts.token1Amount * amount / (poolAmounts.token2Amount - amount);

    return quote
  }

  // Get quote for Token2 (given) -> Token1
  access(all) fun quoteSwapExactToken2ForToken1(amount: UFix64): UFix64 {
    let poolAmounts = self.getPoolAmounts()

    // token1Amount * token2Amount = token1Amount' * token2Amount' = (token2Amount + amount) * (token1Amount - quote)
    let quote = poolAmounts.token1Amount * amount / (poolAmounts.token2Amount + amount);

    return quote
  }

  // Get quote for Token2 -> Token1 (given)
  access(all) fun quoteSwapToken2ForExactToken1(amount: UFix64): UFix64 {
    let poolAmounts = self.getPoolAmounts()

    assert(poolAmounts.token1Amount > amount, message: "Not enough Token1 in the pool")

    // token1Amount * token2Amount = token1Amount' * token2Amount' = (token2Amount + quote) * (token1Amount - amount)
    let quote = poolAmounts.token2Amount * amount / (poolAmounts.token1Amount - amount);

    return quote
  }

  // Swaps Token1 (REVV) -> Token2 (FLOW)
  access(all) fun swapToken1ForToken2(from: @REVV.Vault): @FlowToken.Vault {
    pre {
      !RevvFlowSwapPair.isFrozen: "RevvFlowSwapPair is frozen"
      from.balance > 0.0: "Empty token vault"
    }

    // Calculate amount from pricing curve
    // A fee portion is taken from the final amount
    let token1Amount = from.balance * (1.0 - self.feePercentage)
    let token2Amount = self.quoteSwapExactToken1ForToken2(amount: token1Amount)

    assert(token2Amount > 0.0, message: "Exchanged amount too small")

    self.token1Vault.deposit(from: <- (from as! @{FungibleToken.Vault}))
    emit Trade(token1Amount: token1Amount, token2Amount: token2Amount, side: 1)

    return <- (self.token2Vault.withdraw(amount: token2Amount) as! @FlowToken.Vault)
  }

  // Swap Token2 (FLOW) -> Token1 (REVV)
  access(all) fun swapToken2ForToken1(from: @FlowToken.Vault): @REVV.Vault {
    pre {
      !RevvFlowSwapPair.isFrozen: "RevvFlowSwapPair is frozen"
      from.balance > 0.0: "Empty token vault"
    }

    // Calculate amount from pricing curve
    // A fee portion is taken from the final amount
    let token2Amount = from.balance * (1.0 - self.feePercentage)
    let token1Amount = self.quoteSwapExactToken2ForToken1(amount: token2Amount)

    assert(token1Amount > 0.0, message: "Exchanged amount too small")

    self.token2Vault.deposit(from: <- (from as! @{FungibleToken.Vault}))
    emit Trade(token1Amount: token1Amount, token2Amount: token2Amount, side: 2)

    return <- (self.token1Vault.withdraw(amount: token1Amount) as! @REVV.Vault)
  }

  // Used to add liquidity without minting new liquidity token
  access(all) fun donateLiquidity(from: @RevvFlowSwapPair.TokenBundle) {
    let token1Vault <- from.withdrawToken1()
    let token2Vault <- from.withdrawToken2()

    RevvFlowSwapPair.token1Vault.deposit(from: <- token1Vault)
    RevvFlowSwapPair.token2Vault.deposit(from: <- token2Vault)

    destroy from
  }

  access(all) fun addLiquidity(from: @RevvFlowSwapPair.TokenBundle): @RevvFlowSwapPair.Vault {
    pre {
      self.totalSupply > 0.0: "Pair must be initialized by admin first"
    }

    let token1Vault <- from.withdrawToken1()
    let token2Vault <- from.withdrawToken2()

    assert(token1Vault.balance > 0.0, message: "Empty token1 vault")
    assert(token2Vault.balance > 0.0, message: "Empty token2 vault")

    // shift decimal 4 places to avoid truncation error
    let token1Percentage: UFix64 = (token1Vault.balance * 10000.0) / RevvFlowSwapPair.token1Vault.balance
    let token2Percentage: UFix64 = (token2Vault.balance * 10000.0) / RevvFlowSwapPair.token2Vault.balance

    // final liquidity token minted is the smaller between token1Liquidity and token2Liquidity
    // to maximize profit, user should add liquidity propotional to current liquidity
    let liquidityPercentage = token1Percentage < token2Percentage ? token1Percentage : token2Percentage;

    assert(liquidityPercentage > 0.0, message: "Liquidity too small")

    RevvFlowSwapPair.token1Vault.deposit(from: <- token1Vault)
    RevvFlowSwapPair.token2Vault.deposit(from: <- token2Vault)

    let liquidityTokenVault <- RevvFlowSwapPair.mintTokens(amount: (RevvFlowSwapPair.totalSupply * liquidityPercentage) / 10000.0)

    destroy from
    return <- liquidityTokenVault
  }

  access(all) fun removeLiquidity(from: @RevvFlowSwapPair.Vault): @RevvFlowSwapPair.TokenBundle {
    pre {
      from.balance > 0.0: "Empty liquidity token vault"
      from.balance < RevvFlowSwapPair.totalSupply: "Cannot remove all liquidity"
    }

    // shift decimal 4 places to avoid truncation error
    let liquidityPercentage = (from.balance * 10000.0) / RevvFlowSwapPair.totalSupply

    assert(liquidityPercentage > 0.0, message: "Liquidity too small")

    // Burn liquidity tokens and withdraw
    RevvFlowSwapPair.burnTokens(from: <- from)

    let token1Vault <- RevvFlowSwapPair.token1Vault.withdraw(amount: (RevvFlowSwapPair.token1Vault.balance * liquidityPercentage) / 10000.0) as! @REVV.Vault
    let token2Vault <- RevvFlowSwapPair.token2Vault.withdraw(amount: (RevvFlowSwapPair.token2Vault.balance * liquidityPercentage) / 10000.0) as! @FlowToken.Vault

    let tokenBundle <- RevvFlowSwapPair.createTokenBundle(fromToken1: <- token1Vault, fromToken2: <- token2Vault)
    return <- tokenBundle
  }

  init() {
    self.isFrozen = true // frozen until admin unfreezes
    self.totalSupply = 0.0
    self.feePercentage = 0.003 // 0.3%

    self.TokenStoragePath = /storage/revvFlowSwapLpVault
    self.TokenPublicBalancePath = /public/revvFlowSwapLpBalance
    self.TokenPublicReceiverPath = /public/revvFlowSwapLpReceiver

    // Create the Vault with the total supply of tokens and save it in storage
    let vault <- create Vault(balance: self.totalSupply)

    self.account.storage.save(<-vault, to: /storage/revvFlowSwapLpVault)

    // Setup internal REVV vault
    self.token1Vault <- REVV.createEmptyVault(vaultType: Type<@REVV.Vault>())

    // Setup internal FlowToken vault
    self.token2Vault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())

    let admin <- create Admin()
    self.account.storage.save(<-admin, to: /storage/revvFlowSwapAdmin)

    // Emit an event that shows that the contract was initialized
    emit TokensInitialized(initialSupply: self.totalSupply)
  }
}
