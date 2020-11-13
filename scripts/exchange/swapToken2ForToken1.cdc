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

    let tetherVault = signer.borrow<&TeleportedTetherToken.Vault>(from: /storage/teleportedTetherTokenVault)
        ?? panic("Could not borrow a reference to Vault")
    
    let token2Vault <- tetherVault.withdraw(amount: 14.214) as! @TeleportedTetherToken.Vault

    let token1Vault <- FlowSwapPair.swapToken2ForToken1(from: <-token2Vault)

    flowVault.deposit(from: <- token1Vault)
  }
}
