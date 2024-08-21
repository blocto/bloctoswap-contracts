// This transaction is a template for a transaction
// to add a Vault resource to their account
// so that they can use the FlowSwapPair

import "FungibleToken"
import "FlowSwapPair"

transaction () {

    prepare(signer: auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue) &Account) {
        // Return early if the account already stores a FlowSwapPair Vault
        if signer.storage.borrow<&FlowSwapPair.Vault>(from: /storage/flowUsdtFspLpVault) != nil {
            return
        }

        let vault <- FlowSwapPair.createEmptyVault(vaultType: Type<@FlowSwapPair.Vault>())

         // Create a new FlowSwapPair Vault and put it in storage
        signer.storage.save(<-vault, to: /storage/flowUsdtFspLpVault)
    }
}
