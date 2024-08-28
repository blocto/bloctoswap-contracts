import "FungibleToken"
import "MetadataViews"
import "FungibleTokenMetadataViews"
import "Burner"

access(all) contract TeleportedTetherToken: FungibleToken {

  // An entitlement for allowing the mutation of Administrator resource
  access(all) entitlement AdministratorEntitlement

  // An entitlement for allowing the mutation of TeleportControl resource
  access(all) entitlement TeleportControlEntitlement

  // Frozen flag controlled by Admin
  access(all) var isFrozen: Bool

  // Total supply of TeleportedTetherTokens in existence
  access(all) var totalSupply: UFix64

  // Record teleported Ethereum hashes
  access(all) var teleported: {String: Bool}

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

  // Event that is emitted when new tokens are teleported in from Ethereum (from: Ethereum Address, 20 bytes)
  access(all) event TokensTeleportedIn(amount: UFix64, from: [UInt8], hash: String)

  // Event that is emitted when tokens are destroyed and teleported to Ethereum (to: Ethereum Address, 20 bytes)
  access(all) event TokensTeleportedOut(amount: UFix64, to: [UInt8])

  // Event that is emitted when teleport fee is collected (type 0: out, 1: in)
  access(all) event FeeCollected(amount: UFix64, type: UInt8)

  // Event that is emitted when a new burner resource is created
  access(all) event TeleportAdminCreated(allowedAmount: UFix64)

  // Vault
  //
  // Each user stores an instance of only the Vault in their storage
  // The functions in the Vault and governed by the pre and post conditions
  // in FungibleToken when they are called.
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
        TeleportedTetherToken.totalSupply = TeleportedTetherToken.totalSupply - self.balance
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

    // Asks if the amount can be withdrawn from this vault
    access(all) view fun isAvailableToWithdraw(amount: UFix64): Bool {
      return amount <= self.balance
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
      return <- create Vault(balance: amount)
    }

    // deposit
    //
    // Function that takes a Vault object as an argument and adds
    // its balance to the balance of the owners Vault.
    // It is allowed to destroy the sent Vault because the Vault
    // was a temporary holder of the tokens. The Vault's balance has
    // been consumed and therefore can be destroyed.
    access(all) fun deposit(from: @{FungibleToken.Vault}) {
      let vault <- from as! @TeleportedTetherToken.Vault
      self.balance = self.balance + vault.balance
      emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
      vault.balance = 0.0
      destroy vault
    }

    // Get all the Metadata Views implemented by TeleportedTetherToken
    //
    // @return An array of Types defining the implemented views. This value will be used by
    //         developers to know which parameter to pass to the resolveView() method.
    //
    access(all) view fun getViews(): [Type]{
      return TeleportedTetherToken.getContractViews(resourceType: nil)
    }

    // Get a Metadata View from TeleportedTetherToken
    //
    // @param view: The Type of the desired view.
    // @return A structure representing the requested view.
    //
    access(all) fun resolveView(_ view: Type): AnyStruct? {
      return TeleportedTetherToken.resolveContractView(resourceType: nil, viewType: view)
    }

    access(all) fun createEmptyVault(): @{FungibleToken.Vault} {
      return <- create Vault(balance: 0.0)
    }
  }

  // createEmptyVault
  //
  // Function that creates a new Vault with a balance of zero
  // and returns it to the calling context. A user must call this function
  // and store the returned Vault in their storage in order to allow their
  // account to be able to receive deposits of this token type.
  //
  access(all) fun createEmptyVault(vaultType: Type): @TeleportedTetherToken.Vault {
    return <- create Vault(balance: 0.0)
  }

  // Gets a list of the metadata views that this contract supports
  access(all) view fun getContractViews(resourceType: Type?): [Type] {
    return [Type<FungibleTokenMetadataViews.FTView>(),
            Type<FungibleTokenMetadataViews.FTDisplay>(),
            Type<FungibleTokenMetadataViews.FTVaultData>(),
            Type<FungibleTokenMetadataViews.TotalSupply>()]
  }

  // Get a Metadata View from TeleportedTetherToken
  //
  // @param view: The Type of the desired view.
  // @return A structure representing the requested view.
  //
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
            url: "https://raw.githubusercontent.com/blocto/assets/main/color/flow/tusdt.svg"
          ),
          mediaType: "image/svg+xml"
        )
        let medias = MetadataViews.Medias([media])
        return FungibleTokenMetadataViews.FTDisplay(
          name: "teleported USDT",
          symbol: "tUSDT",
          description: "tUSDT stands for teleported USDT on Flow Blockchain.",
          externalURL: MetadataViews.ExternalURL("https://blocto.io"),
          logos: medias,
          socials: {
            "twitter": MetadataViews.ExternalURL("https://twitter.com/BloctoApp")
          }
        )
      case Type<FungibleTokenMetadataViews.FTVaultData>():
        let vaultRef = TeleportedTetherToken.account.storage.borrow<auth(FungibleToken.Withdraw) &TeleportedTetherToken.Vault>(from: /storage/teleportedTetherTokenVault)
          ?? panic("Could not borrow reference to the contract's Vault!")
        return FungibleTokenMetadataViews.FTVaultData(
          storagePath: /storage/teleportedTetherTokenVault,
          receiverPath: /public/teleportedTetherTokenReceiver,
          metadataPath: /public/teleportedTetherTokenBalance,
          receiverLinkedType: Type<&{FungibleToken.Receiver, FungibleToken.Vault}>(),
          metadataLinkedType: Type<&{FungibleToken.Balance, FungibleToken.Vault}>(),
          createEmptyVaultFunction: (fun (): @{FungibleToken.Vault} {
            return <- vaultRef.createEmptyVault()
          })
        )
      case Type<FungibleTokenMetadataViews.TotalSupply>():
        return FungibleTokenMetadataViews.TotalSupply(totalSupply: TeleportedTetherToken.totalSupply)
    }
    return nil
  }

  access(all) resource Allowance {
    access(all) var balance: UFix64

    // initialize the balance at resource creation time
    init(balance: UFix64) {
      self.balance = balance
    }
  }

  access(all) resource Administrator {

    // createNewTeleportAdmin
    //
    // Function that creates and returns a new teleport admin resource
    //
    access(AdministratorEntitlement) fun createNewTeleportAdmin(allowedAmount: UFix64): @TeleportAdmin {
      emit TeleportAdminCreated(allowedAmount: allowedAmount)
      return <- create TeleportAdmin(allowedAmount: allowedAmount)
    }

    access(AdministratorEntitlement) fun freeze() {
      TeleportedTetherToken.isFrozen = true
    }

    access(AdministratorEntitlement) fun unfreeze() {
      TeleportedTetherToken.isFrozen = false
    }

    access(AdministratorEntitlement) fun createAllowance(allowedAmount: UFix64): @Allowance {
      return <- create Allowance(balance: allowedAmount)
    }
  }

  access(all) resource interface TeleportUser {
    // fee collected when token is teleported from Ethereum to Flow
    access(all) var inwardFee: UFix64

    // fee collected when token is teleported from Flow to Ethereum
    access(all) var outwardFee: UFix64
    
    // the amount of tokens that the minter is allowed to mint
    access(all) var allowedAmount: UFix64

    // corresponding controller account on Ethereum
    access(all) var ethereumAdminAccount: [UInt8]

    access(all) fun teleportOut(from: @{FungibleToken.Vault}, to: [UInt8])

    access(all) fun depositAllowance(from: @Allowance)
  }

  access(all) resource interface TeleportControl {
    access(TeleportControlEntitlement) fun teleportIn(amount: UFix64, from: [UInt8], hash: String): @TeleportedTetherToken.Vault

    access(TeleportControlEntitlement) fun withdrawFee(amount: UFix64): @{FungibleToken.Vault}
    
    access(TeleportControlEntitlement) fun updateInwardFee(fee: UFix64)

    access(TeleportControlEntitlement) fun updateOutwardFee(fee: UFix64)

    access(TeleportControlEntitlement) fun updateEthereumAdminAccount(account: [UInt8])
  }

  // TeleportAdmin resource
  //
  //  Resource object that has the capability to mint teleported tokens
  //  upon receiving teleport request from Ethereum side
  //
  access(all) resource TeleportAdmin: TeleportUser, TeleportControl {
    
    // the amount of tokens that the minter is allowed to mint
    access(all) var allowedAmount: UFix64

    // receiver reference to collect teleport fee
    access(all) let feeCollector: @TeleportedTetherToken.Vault

    // fee collected when token is teleported from Ethereum to Flow
    access(all) var inwardFee: UFix64

    // fee collected when token is teleported from Flow to Ethereum
    access(all) var outwardFee: UFix64

    // corresponding controller account on Ethereum
    access(all) var ethereumAdminAccount: [UInt8]

    // teleportIn
    //
    // Function that mints new tokens, adds them to the total supply,
    // and returns them to the calling context.
    //
    access(TeleportControlEntitlement) fun teleportIn(amount: UFix64, from: [UInt8], hash: String): @TeleportedTetherToken.Vault {
      pre {
        !TeleportedTetherToken.isFrozen: "Teleport service is frozen"
        amount <= self.allowedAmount: "Amount minted must be less than the allowed amount"
        amount > self.inwardFee: "Amount minted must be greater than inward teleport fee"
        from.length == 20: "Ethereum address should be 20 bytes"
        hash.length == 64: "Ethereum tx hash should be 32 bytes"
        !(TeleportedTetherToken.teleported[hash] ?? false): "Same hash already teleported"
      }
      TeleportedTetherToken.totalSupply = TeleportedTetherToken.totalSupply + amount
      self.allowedAmount = self.allowedAmount - amount

      TeleportedTetherToken.teleported[hash] = true
      emit TokensTeleportedIn(amount: amount, from: from, hash: hash)

      let vault <- create Vault(balance: amount)
      let fee <- vault.withdraw(amount: self.inwardFee)

      self.feeCollector.deposit(from: <-fee)
      emit FeeCollected(amount: self.inwardFee, type: 1)

      return <- vault
    }

    // teleportOut
    //
    // Function that destroys a Vault instance, effectively burning the tokens.
    //
    access(all) fun teleportOut(from: @{FungibleToken.Vault}, to: [UInt8]) {
      pre {
        !TeleportedTetherToken.isFrozen: "Teleport service is frozen"
        to.length == 20: "Ethereum address should be 20 bytes"
      }

      let vault <- from as! @TeleportedTetherToken.Vault
      let fee <- vault.withdraw(amount: self.outwardFee)

      self.feeCollector.deposit(from: <-fee)
      emit FeeCollected(amount: self.outwardFee, type: 0)

      let amount = vault.balance
      Burner.burn(<- vault)
      emit TokensTeleportedOut(amount: amount, to: to)
    }

    access(TeleportControlEntitlement) fun withdrawFee(amount: UFix64): @{FungibleToken.Vault} {
      return <- self.feeCollector.withdraw(amount: amount)
    }

    access(TeleportControlEntitlement) fun updateInwardFee(fee: UFix64) {
      self.inwardFee = fee
    }

    access(TeleportControlEntitlement) fun updateOutwardFee(fee: UFix64) {
      self.outwardFee = fee
    }

    access(TeleportControlEntitlement) fun updateEthereumAdminAccount(account: [UInt8]) {
      pre {
        account.length == 20: "Ethereum address should be 20 bytes"
      }

      self.ethereumAdminAccount = account
    }

    access(all) view fun getFeeAmount(): UFix64 {
      return self.feeCollector.balance
    }

    access(all) fun depositAllowance(from: @Allowance) {
      self.allowedAmount = self.allowedAmount + from.balance

      destroy from
    }

    init(allowedAmount: UFix64) {
      self.allowedAmount = allowedAmount

      self.feeCollector <- TeleportedTetherToken.createEmptyVault(vaultType: Type<@TeleportedTetherToken.Vault>())
      self.inwardFee = 0.01
      self.outwardFee = 3.0

      self.ethereumAdminAccount = []
    }
  }

  init() {
    self.isFrozen = false
    self.totalSupply = 0.0
    self.teleported = {}
    self.TokenStoragePath = /storage/teleportedTetherTokenVault
    self.TokenPublicBalancePath = /public/teleportedTetherTokenBalance
    self.TokenPublicReceiverPath = /public/teleportedTetherTokenReceiver

    let admin <- create Administrator()
    self.account.storage.save(<- admin, to: /storage/teleportedTetherTokenAdmin)

    // Emit an event that shows that the contract was initialized
    emit TokensInitialized(initialSupply: self.totalSupply)
  }
}