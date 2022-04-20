import FungibleToken from "../../../contracts/token/FungibleToken.cdc"
import TeleportedSportiumToken from "../../../contracts/token/TeleportedSportiumToken.cdc"

transaction {

    prepare(signer: AuthAccount) {

        // If the account is already set up that's not a problem, but we don't want to replace it
        if(signer.borrow<&TeleportedSportiumToken.Vault>(from: TeleportedSportiumToken.TokenStoragePath) != nil) {
            return
        }
        
        // Create a new Starly Token Vault and put it in storage
        signer.save(<-TeleportedSportiumToken.createEmptyVault(), to: TeleportedSportiumToken.TokenStoragePath)

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        signer.link<&TeleportedSportiumToken.Vault{FungibleToken.Receiver}>(
            TeleportedSportiumToken.TokenPublicReceiverPath,
            target: TeleportedSportiumToken.TokenStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the balance field through the Balance interface
        signer.link<&TeleportedSportiumToken.Vault{FungibleToken.Balance}>(
            TeleportedSportiumToken.TokenPublicBalancePath,
            target: TeleportedSportiumToken.TokenStoragePath
        )
    }
}
