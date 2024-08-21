// This transaction is a template for a transaction
// to add a Vault resource to their account
// so that they can use the TeleportedTetherToken (USDT)

import "FungibleToken"
import "TeleportedTetherToken"
import "ViewResolver"
import "FungibleTokenMetadataViews"

transaction () {

    prepare(signer: auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue) &Account) {

        let vaultData = TeleportedTetherToken.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTVaultData>()) as! FungibleTokenMetadataViews.FTVaultData?
            ?? panic("ViewResolver does not resolve FTVaultData view")

        // Return early if the account already stores a TeleportedTetherToken Vault
        if signer.storage.borrow<&TeleportedTetherToken.Vault>(from: vaultData.storagePath) != nil {
            return
        }

        let vault <- TeleportedTetherToken.createEmptyVault(vaultType: Type<@TeleportedTetherToken.Vault>())

        // Create a new TeleportedTetherToken Vault and put it in storage
        signer.storage.save(<-vault, to: vaultData.storagePath)

        // Create a public capability to the Vault that exposes the Vault interfaces
        let vaultCap = signer.capabilities.storage.issue<&TeleportedTetherToken.Vault>(
            vaultData.storagePath
        )
        signer.capabilities.publish(vaultCap, at: vaultData.metadataPath)

        // Create a public Capability to the Vault's Receiver functionality
        let receiverCap = signer.capabilities.storage.issue<&TeleportedTetherToken.Vault>(
            vaultData.storagePath
        )
        signer.capabilities.publish(receiverCap, at: vaultData.receiverPath)
    }
}
