// This transaction is a template for a transaction
// to add a Vault resource to their account
// so that they can use the teleportedTetherToken (USDT)

import FungibleToken from 0x01
import FlowToken from 0x02
import TeleportedTetherToken from 0x03
import FlowSwapPair from 0x04

transaction {
  prepare(signer: AuthAccount) {
    let flowSwapPairVault = signer.borrow<&FlowSwapPair.Vault>(from: /storage/flowSwapPairTokenVault)
        ?? panic("Could not borrow a reference to Vault")
    
    let liquidityTokenVault <- flowSwapPairVault.withdraw(amount: 1.0) as! @FlowSwapPair.Vault
    let tokenBundle <- FlowSwapPair.removeLiquidity(from: <-liquidityTokenVault)

    let flowTokenVault = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
        ?? panic("Could not borrow a reference to Vault")

    let tetherVault = signer.borrow<&TeleportedTetherToken.Vault>(from: /storage/teleportedTetherTokenVault)
        ?? panic("Could not borrow a reference to Vault")
        
    flowTokenVault.deposit(from: <- tokenBundle.withdrawToken1())
    tetherVault.deposit(from: <- tokenBundle.withdrawToken2())

    destroy tokenBundle
  }
}
