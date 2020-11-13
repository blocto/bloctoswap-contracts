// This transaction is a template for a transaction
// to add a Vault resource to their account
// so that they can use the teleportedTetherToken (USDT)

import FungibleToken from 0x9a0766d93b6608b7
import FlowToken from 0x7e60df042a9c0868
import TeleportedTetherToken from 0xf4772588268a160f
import FlowSwapPair from 0x10109c55377016d0

transaction(token1Amount: UFix64, token2Amount: UFix64) {
  prepare(signer: AuthAccount) {
    let flowVault = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
        ?? panic("Could not borrow a reference to Vault")
    
    let token1Vault <- flowVault.withdraw(amount: token1Amount) as! @FlowToken.Vault

    let tetherVault = signer.borrow<&TeleportedTetherToken.Vault>(from: /storage/teleportedTetherTokenVault)
        ?? panic("Could not borrow a reference to Vault")
    
    let token2Vault <- tetherVault.withdraw(amount: token2Amount) as! @TeleportedTetherToken.Vault

    let adminRef = signer.borrow<&FlowSwapPair.Admin>(from: /storage/flowSwapPairAdmin)
        ?? panic("Could not borrow a reference to Admin")

    let tokenBundle <- FlowSwapPair.createTokenBundle(fromToken1: <- token1Vault, fromToken2: <- token2Vault);
    let liquidityTokenVault <- adminRef.addInitialLiquidity(from: <- tokenBundle)

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

    let liquidityTokenRef = signer.borrow<&FlowSwapPair.Vault>(from: /storage/flowSwapPairTokenVault)
        ?? panic("Could not borrow a reference to Vault")

    liquidityTokenRef.deposit(from: <- liquidityTokenVault)
  }
}
 