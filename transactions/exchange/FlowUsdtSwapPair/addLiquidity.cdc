import FungibleToken from 0xFUNGIBLETOKENADDRESS
import FlowToken from 0xFLOWTOKENADDRESS
import TeleportedTetherToken from 0xTELEPORTEDUSDTADDRESS
import FlowSwapPair from 0xFLOWSWAPPAIRADDRESS

transaction(token1Amount: UFix64, token2Amount: UFix64) {
  // The Vault references that holds the tokens that are being transferred
  let flowTokenVaultRef: &FlowToken.Vault
  let tetherVaultRef: &TeleportedTetherToken.Vault

  // The proxy holder reference for access control
  let swapProxyRef: &FlowSwapPair.SwapProxy

  // The Vault reference for liquidity tokens
  let liquidityTokenRef: &FlowSwapPair.Vault

  prepare(signer: AuthAccount, proxyHolder: AuthAccount) {
    self.flowTokenVaultRef = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
        ?? panic("Could not borrow a reference to Vault")

    self.tetherVaultRef = signer.borrow<&TeleportedTetherToken.Vault>(from: /storage/teleportedTetherTokenVault)
        ?? panic("Could not borrow a reference to Vault")

    if signer.borrow<&FlowSwapPair.Vault>(from: FlowSwapPair.TokenStoragePath) == nil {
      // Create a new flowToken Vault and put it in storage
      signer.save(<-FlowSwapPair.createEmptyVault(), to: FlowSwapPair.TokenStoragePath)

      // Create a public capability to the Vault that only exposes
      // the deposit function through the Receiver interface
      signer.link<&FlowSwapPair.Vault{FungibleToken.Receiver}>(
        FlowSwapPair.TokenPublicReceiverPath,
        target: FlowSwapPair.TokenStoragePath
      )

      // Create a public capability to the Vault that only exposes
      // the balance field through the Balance interface
      signer.link<&FlowSwapPair.Vault{FungibleToken.Balance}>(
        FlowSwapPair.TokenPublicBalancePath,
        target: FlowSwapPair.TokenStoragePath
      )
    }

    self.swapProxyRef = proxyHolder.borrow<&FlowSwapPair.SwapProxy>(from: /storage/flowUsdtSwapProxy)
      ?? panic("Could not borrow a reference to proxy holder")

    self.liquidityTokenRef = signer.borrow<&FlowSwapPair.Vault>(from: FlowSwapPair.TokenStoragePath)
      ?? panic("Could not borrow a reference to Vault")
  }

  execute {
    // Withdraw tokens
    let token1Vault <- self.flowTokenVaultRef.withdraw(amount: token1Amount) as! @FlowToken.Vault
    let token2Vault <- self.tetherVaultRef.withdraw(amount: token2Amount) as! @TeleportedTetherToken.Vault

    // Provide liquidity and get liquidity provider tokens
    let tokenBundle <- FlowSwapPair.createTokenBundle(fromToken1: <- token1Vault, fromToken2: <- token2Vault)
    let liquidityTokenVault <- self.swapProxyRef.addLiquidity(from: <- tokenBundle)

    // Keep the liquidity provider tokens
    self.liquidityTokenRef.deposit(from: <- liquidityTokenVault)
  }
}
