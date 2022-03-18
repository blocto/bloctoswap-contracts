import FungibleToken from "../../../contracts/token/FungibleToken.cdc"
import StarlyToken from "../../../contracts/token/StarlyToken.cdc"

transaction {

    prepare(signer: AuthAccount) {

        // If the account is already set up that's not a problem, but we don't want to replace it
        if(signer.borrow<&StarlyToken.Vault>(from: StarlyToken.TokenStoragePath) != nil) {
            return
        }
        
        // Create a new Starly Token Vault and put it in storage
        signer.save(<-StarlyToken.createEmptyVault(), to: StarlyToken.TokenStoragePath)

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        signer.link<&StarlyToken.Vault{FungibleToken.Receiver}>(
            StarlyToken.TokenPublicReceiverPath,
            target: StarlyToken.TokenStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the balance field through the Balance interface
        signer.link<&StarlyToken.Vault{FungibleToken.Balance}>(
            StarlyToken.TokenPublicBalancePath,
            target: StarlyToken.TokenStoragePath
        )
    }
}
