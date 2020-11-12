// This transaction is a template for a transaction
// to add a Vault resource to their account
// so that they can use the teleportedTetherToken (USDT)

import FungibleToken from 0xFUNGIBLETOKENADDRESS
import TeleportedTetherToken from 0xTOKENADDRESS

transaction {

  prepare(signer: AuthAccount) {

    if signer.borrow<&TeleportedTetherToken.Vault>(from: TeleportedTetherToken.TokenStoragePath) == nil {
      // Create a new teleportedTetherToken Vault and put it in storage
      signer.save(<-TeleportedTetherToken.createEmptyVault(), to: TeleportedTetherToken.TokenStoragePath)

      // Create a public capability to the Vault that only exposes
      // the deposit function through the Receiver interface
      signer.link<&TeleportedTetherToken.Vault{FungibleToken.Receiver}>(
        TeleportedTetherToken.TokenPublicReceiverPath,
        target: TeleportedTetherToken.TokenStoragePath
      )

      // Create a public capability to the Vault that only exposes
      // the balance field through the Balance interface
      signer.link<&TeleportedTetherToken.Vault{FungibleToken.Balance}>(
        TeleportedTetherToken.TokenPublicBalancePath,
        target: TeleportedTetherToken.TokenStoragePath
      )
    }
  }
}
