// This transaction is a template for a transaction
// to add a Vault resource to their account
// so that they can use the teleportedTetherToken (USDT)

import FungibleToken from 0x01
import FlowToken from 0x02
import TeleportedTetherToken from 0x03
import FlowSwapPair from 0x04

transaction {
  prepare(signer: AuthAccount) {
    let flowVault = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
        ?? panic("Could not borrow a reference to Vault")
    
    let token1Vault <- flowVault.withdraw(amount: 10.0) as! @FlowToken.Vault

    let tetherVault = signer.borrow<&TeleportedTetherToken.Vault>(from: /storage/teleportedTetherTokenVault)
        ?? panic("Could not borrow a reference to Vault")

    let token2Vault <- FlowSwapPair.swapToken1ForToken2(from: <-token1Vault)

    tetherVault.deposit(from: <- token2Vault)
  }
}
