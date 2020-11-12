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
    
    let token1Vault <- flowVault.withdraw(amount: 10.0)

    let tetherVault = signer.borrow<&TeleportedTetherToken.Vault>(from: /storage/teleportedTetherTokenVault)
        ?? panic("Could not borrow a reference to Vault")
    
    let token2Vault <- tetherVault.withdraw(amount: 10.0)

    let adminRef = signer.borrow<&FlowSwapPair.Admin>(from: /storage/flowSwapPairAdmin)
        ?? panic("Could not borrow a reference to Admin")

    let tokenBundle <- FlowSwapPair.createEmptyTokenBundle();
    tokenBundle.depositToken1(from: <- (token1Vault as! @FlowToken.Vault))
    tokenBundle.depositToken2(from: <- (token2Vault as! @TeleportedTetherToken.Vault))

    let liquidityTokenVault <- adminRef.addInitialLiquidity(from: <- tokenBundle)

    let liquidityTokenRef = signer.borrow<&FlowSwapPair.Vault>(from: /storage/flowSwapPairTokenVault)
        ?? panic("Could not borrow a reference to Vault")

    liquidityTokenRef.deposit(from: <- liquidityTokenVault)
  }
}
