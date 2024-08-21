import "FungibleToken"
import "FlowToken"
import "TeleportedTetherToken"
import "FlowSwapPair"
import "ViewResolver"
import "FungibleTokenMetadataViews"

transaction(token1Amount: UFix64, token2Amount: UFix64) {
  // The Vault references that holds the tokens that are being transferred
  let flowTokenVaultRef: auth(FungibleToken.Withdraw) &FlowToken.Vault
  let tetherVaultRef: auth(FungibleToken.Withdraw) &TeleportedTetherToken.Vault

  // The Vault reference for liquidity tokens
  let liquidityTokenRef: &FlowSwapPair.Vault

  // The Admin reference
  let adminRef: &FlowSwapPair.Admin

  prepare(signer: auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue) &Account) {
    let flowVaultData = FlowToken.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTVaultData>()) as! FungibleTokenMetadataViews.FTVaultData?
        ?? panic("ViewResolver does not resolve FTVaultData view")

    let tusdtVaultData = TeleportedTetherToken.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTVaultData>()) as! FungibleTokenMetadataViews.FTVaultData?
        ?? panic("ViewResolver does not resolve FTVaultData view")

    let lpVaultData = FlowSwapPair.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTVaultData>()) as! FungibleTokenMetadataViews.FTVaultData?
        ?? panic("ViewResolver does not resolve FTVaultData view")

    self.flowTokenVaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: flowVaultData.storagePath)
      ?? panic("Could not borrow reference to the owner's Vault!")

    self.tetherVaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &TeleportedTetherToken.Vault>(from: tusdtVaultData.storagePath)
      ?? panic("Could not borrow reference to the owner's Vault!")

    if signer.storage.borrow<&FlowSwapPair.Vault>(from: lpVaultData.storagePath) == nil {
      let vault <- FlowSwapPair.createEmptyVault(vaultType: Type<@FlowSwapPair.Vault>())

      // Create a new FlowSwapPair Vault and put it in storage
      signer.storage.save(<-vault, to: lpVaultData.storagePath)

      // Create a public capability to the Vault that exposes the Vault interfaces
      let vaultCap = signer.capabilities.storage.issue<&FlowSwapPair.Vault>(
          lpVaultData.storagePath
      )
      signer.capabilities.publish(vaultCap, at: lpVaultData.metadataPath)

      // Create a public Capability to the Vault's Receiver functionality
      let receiverCap = signer.capabilities.storage.issue<&FlowSwapPair.Vault>(
          lpVaultData.storagePath
      )
      signer.capabilities.publish(receiverCap, at: lpVaultData.receiverPath)
    }

    self.liquidityTokenRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowSwapPair.Vault>(from: lpVaultData.storagePath)
      ?? panic("Could not borrow reference to the owner's Vault!")

    self.adminRef = signer.storage.borrow<&FlowSwapPair.Admin>(from: /storage/flowSwapPairAdmin)
      ?? panic("Could not borrow a reference to the admin resource")
  }

  execute {
    // Withdraw tokens
    let token1Vault <- self.flowTokenVaultRef.withdraw(amount: token1Amount) as! @FlowToken.Vault
    let token2Vault <- self.tetherVaultRef.withdraw(amount: token2Amount) as! @TeleportedTetherToken.Vault

    // Provide liquidity and get liquidity provider tokens
    let tokenBundle <- FlowSwapPair.createTokenBundle(fromToken1: <- token1Vault, fromToken2: <- token2Vault)
    let liquidityTokenVault <- self.adminRef.addInitialLiquidity(from: <- tokenBundle)

    // Keep the liquidity provider tokens
    self.liquidityTokenRef.deposit(from: <- liquidityTokenVault)
  }
}
