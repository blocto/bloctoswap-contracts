import FungibleToken from "../../../contracts/token/FungibleToken.cdc"
import StarlyToken from "../../../contracts/token/StarlyToken.cdc"
import FlowToken from "../../../contracts/token/FlowToken.cdc"
import StarlyFlowSwapPair from "../../../contracts/exchange/StarlyFlowSwapPair.cdc"

transaction(token1Amount: UFix64, token2Amount: UFix64) {
  // The Vault references that holds the tokens that are being transferred
  let starlyVault: &StarlyToken.Vault
  let flowVault: &FlowToken.Vault

  // The Vault reference for liquidity tokens
  let liquidityTokenRef: &StarlyFlowSwapPair.Vault

  prepare(signer: AuthAccount) {
    self.starlyVault = signer.borrow<&StarlyToken.Vault>(from: StarlyToken.TokenStoragePath)
        ?? panic("Could not borrow a reference to Vault")

    self.flowVault = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
        ?? panic("Could not borrow a reference to Vault")

    if signer.borrow<&StarlyFlowSwapPair.Vault>(from: StarlyFlowSwapPair.TokenStoragePath) == nil {
      // Create a new StarlyFlowSwapPair LP Token Vault and put it in storage
      signer.save(<-StarlyFlowSwapPair.createEmptyVault(), to: StarlyFlowSwapPair.TokenStoragePath)

      // Create a public capability to the Vault that only exposes
      // the deposit function through the Receiver interface
      signer.link<&StarlyFlowSwapPair.Vault{FungibleToken.Receiver}>(
        StarlyFlowSwapPair.TokenPublicReceiverPath,
        target: StarlyFlowSwapPair.TokenStoragePath
      )

      // Create a public capability to the Vault that only exposes
      // the balance field through the Balance interface
      signer.link<&StarlyFlowSwapPair.Vault{FungibleToken.Balance}>(
        StarlyFlowSwapPair.TokenPublicBalancePath,
        target: StarlyFlowSwapPair.TokenStoragePath
      )
    }

    self.liquidityTokenRef = signer.borrow<&StarlyFlowSwapPair.Vault>(from: StarlyFlowSwapPair.TokenStoragePath)
      ?? panic("Could not borrow a reference to Vault")
  }

  execute {
    // Withdraw tokens
    let token1Vault <- self.starlyVault.withdraw(amount: token1Amount) as! @StarlyToken.Vault
    let token2Vault <- self.flowVault.withdraw(amount: token2Amount) as! @FlowToken.Vault

    // Provide liquidity and get liquidity provider tokens
    let tokenBundle <- StarlyFlowSwapPair.createTokenBundle(fromToken1: <- token1Vault, fromToken2: <- token2Vault)
    let liquidityTokenVault <- StarlyFlowSwapPair.addLiquidity(from: <- tokenBundle)

    // Keep the liquidity provider tokens
    self.liquidityTokenRef.deposit(from: <- liquidityTokenVault)
  }
}
