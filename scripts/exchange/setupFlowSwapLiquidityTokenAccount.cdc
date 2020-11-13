// This transaction is a template for a transaction
// to add a Vault resource to their account
// so that they can use the FlowToken

import FungibleToken from 0x01
import FlowSwapPair from 0x04

transaction {

  prepare(signer: AuthAccount) {

    if signer.borrow<&FlowSwapPair.Vault>(from: /storage/flowSwapPairTokenVault) == nil {
      // Create a new flowToken Vault and put it in storage
      signer.save(<-FlowSwapPair.createEmptyVault(), to: /storage/flowSwapPairTokenVault)

      // Create a public capability to the Vault that only exposes
      // the deposit function through the Receiver interface
      signer.link<&FlowSwapPair.Vault{FungibleToken.Receiver}>(
        /public/flowSwapPairTokenReceiver,
        target: /storage/flowSwapPairTokenVault
      )

      // Create a public capability to the Vault that only exposes
      // the balance field through the Balance interface
      signer.link<&FlowSwapPair.Vault{FungibleToken.Balance}>(
        /public/flowSwapPairTokenBalance,
        target: /storage/flowSwapPairTokenVault
      )
    }
  }
}
