import FungibleToken from "../../../contracts/token/FungibleToken.cdc"
import FiatToken from "../../../contracts/token/FiatToken.cdc"

transaction {

    prepare(signer: AuthAccount) {

        // If the account is already set up that's not a problem, but we don't want to replace it
        if(signer.borrow<&FiatToken.Vault>(from: FiatToken.VaultStoragePath) != nil) {
            return
        }
        
        // Create a new Blocto Token Vault and put it in storage
        signer.save(<-FiatToken.createEmptyVault(), to: FiatToken.VaultStoragePath)

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        signer.link<&FiatToken.Vault{FungibleToken.Receiver}>(
            FiatToken.VaultReceiverPubPath,
            target: FiatToken.VaultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the balance field through the Balance interface
        signer.link<&FiatToken.Vault{FungibleToken.Balance}>(
            FiatToken.VaultBalancePubPath,
            target: FiatToken.VaultStoragePath
        )
    }
}
