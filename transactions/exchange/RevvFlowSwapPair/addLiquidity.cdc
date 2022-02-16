import FungibleToken from "../../../contracts/token/FungibleToken.cdc"
import REVV from "../../../contracts/token/REVV.cdc"
import FlowToken from "../../../contracts/token/FlowToken.cdc"
import RevvFlowSwapPair from "../../../contracts/exchange/RevvFlowSwapPair.cdc"

transaction(token1Amount: UFix64, token2Amount: UFix64) {
  // The Vault references that holds the tokens that are being transferred
  let revvVault: &REVV.Vault
  let flowVault: &FlowToken.Vault

  // The Vault reference for liquidity tokens
  let liquidityTokenRef: &RevvFlowSwapPair.Vault

  prepare(signer: AuthAccount) {
    self.revvVault = signer.borrow<&REVV.Vault>(from: REVV.RevvVaultStoragePath)
        ?? panic("Could not borrow a reference to Vault")

    self.flowVault = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
        ?? panic("Could not borrow a reference to Vault")

    if signer.borrow<&RevvFlowSwapPair.Vault>(from: RevvFlowSwapPair.TokenStoragePath) == nil {
      // Create a new RevvFlowSwapPair LP Token Vault and put it in storage
      signer.save(<-RevvFlowSwapPair.createEmptyVault(), to: RevvFlowSwapPair.TokenStoragePath)

      // Create a public capability to the Vault that only exposes
      // the deposit function through the Receiver interface
      signer.link<&RevvFlowSwapPair.Vault{FungibleToken.Receiver}>(
        RevvFlowSwapPair.TokenPublicReceiverPath,
        target: RevvFlowSwapPair.TokenStoragePath
      )

      // Create a public capability to the Vault that only exposes
      // the balance field through the Balance interface
      signer.link<&RevvFlowSwapPair.Vault{FungibleToken.Balance}>(
        RevvFlowSwapPair.TokenPublicBalancePath,
        target: RevvFlowSwapPair.TokenStoragePath
      )
    }

    self.liquidityTokenRef = signer.borrow<&RevvFlowSwapPair.Vault>(from: RevvFlowSwapPair.TokenStoragePath)
      ?? panic("Could not borrow a reference to Vault")
  }

  execute {
    // Withdraw tokens
    let token1Vault <- self.revvVault.withdraw(amount: token1Amount) as! @REVV.Vault
    let token2Vault <- self.flowVault.withdraw(amount: token2Amount) as! @FlowToken.Vault

    // Provide liquidity and get liquidity provider tokens
    let tokenBundle <- RevvFlowSwapPair.createTokenBundle(fromToken1: <- token1Vault, fromToken2: <- token2Vault)
    let liquidityTokenVault <- RevvFlowSwapPair.addLiquidity(from: <- tokenBundle)

    // Keep the liquidity provider tokens
    self.liquidityTokenRef.deposit(from: <- liquidityTokenVault)
  }
}
