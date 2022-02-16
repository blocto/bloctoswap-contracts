import FungibleToken from "../../../contracts/token/FungibleToken.cdc"
import REVV from "../../../contracts/token/REVV.cdc"

transaction {

    prepare(signer: AuthAccount) {

        // If the account is already set up that's not a problem, but we don't want to replace it
        if(signer.borrow<&REVV.Vault>(from: REVV.RevvVaultStoragePath) != nil) {
            return
        }
        
        // Create a new Blocto Token Vault and put it in storage
        signer.save(<-REVV.createEmptyVault(), to: REVV.RevvVaultStoragePath)

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        signer.link<&REVV.Vault{FungibleToken.Receiver}>(
            REVV.RevvReceiverPublicPath,
            target: REVV.RevvVaultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the balance field through the Balance interface
        signer.link<&REVV.Vault{FungibleToken.Balance}>(
            REVV.RevvBalancePublicPath,
            target: REVV.RevvVaultStoragePath
        )
    }
}
