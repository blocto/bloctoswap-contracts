// This transaction is a template for a transaction
// to add a Vault resource to their account
// so that they can use the FlowSwapPair

import "FungibleToken"
import "FlowSwapPair"
import "ViewResolver"
import "FungibleTokenMetadataViews"

transaction () {

    prepare(signer: auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue) &Account) {

        let vaultData = FlowSwapPair.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTVaultData>()) as! FungibleTokenMetadataViews.FTVaultData?
            ?? panic("ViewResolver does not resolve FTVaultData view")

        // Return early if the account already stores a FlowSwapPair Vault
        if signer.storage.borrow<&FlowSwapPair.Vault>(from: vaultData.storagePath) != nil {
            return
        }

        let vault <- FlowSwapPair.createEmptyVault(vaultType: Type<@FlowSwapPair.Vault>())

        // Create a new FlowSwapPair Vault and put it in storage
        signer.storage.save(<-vault, to: vaultData.storagePath)

        // Create a public capability to the Vault that exposes the Vault interfaces
        let vaultCap = signer.capabilities.storage.issue<&FlowSwapPair.Vault>(
            vaultData.storagePath
        )
        signer.capabilities.publish(vaultCap, at: vaultData.metadataPath)

        // Create a public Capability to the Vault's Receiver functionality
        let receiverCap = signer.capabilities.storage.issue<&FlowSwapPair.Vault>(
            vaultData.storagePath
        )
        signer.capabilities.publish(receiverCap, at: vaultData.receiverPath)
    }
}
