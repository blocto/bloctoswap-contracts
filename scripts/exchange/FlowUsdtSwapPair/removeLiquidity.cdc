import FungibleToken from 0xFUNGIBLETOKENADDRESS
import FlowToken from 0xFLOWTOKENADDRESS
import TeleportedTetherToken from 0xTELEPORTEDUSDTADDRESS
import FlowSwapPair from 0xFLOWSWAPPAIRADDRESS
import FlowSwapPairProxy from 0xFLOWSWAPPAIRADDRESS

transaction(amount: UFix64) {
  // The Vault reference for liquidity tokens
  let liquidityTokenRef: &FlowSwapPair.Vault

  // The proxy holder reference for access control
  let swapProxyRef: &FlowSwapPairProxy.SwapProxy

  // The Vault references that holds the tokens that are being transferred
  let flowTokenVaultRef: &FlowToken.Vault
  let tetherVaultRef: &TeleportedTetherToken.Vault

  prepare(signer: AuthAccount, proxyHolder: AuthAccount) {
    self.liquidityTokenRef = signer.borrow<&FlowSwapPair.Vault>(from: FlowSwapPair.TokenStoragePath)
      ?? panic("Could not borrow a reference to Vault")

    self.swapProxyRef = proxyHolder.borrow<&FlowSwapPairProxy.SwapProxy>(from: FlowSwapPairProxy.SwapProxyStoragePath)
      ?? panic("Could not borrow a reference to proxy holder")

    self.flowTokenVaultRef = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
      ?? panic("Could not borrow a reference to Vault")

    self.tetherVaultRef = signer.borrow<&TeleportedTetherToken.Vault>(from: /storage/teleportedTetherTokenVault)
      ?? panic("Could not borrow a reference to Vault")
  }

  execute {
    // Withdraw liquidity provider tokens
    let liquidityTokenRef <- self.liquidityTokenRef.withdraw(amount: amount) as! @FlowSwapPair.Vault

    // Take back liquidity
    let tokenBundle <- self.swapProxyRef.removeLiquidity(from: <-liquidityTokenVault)

    // Deposit liquidity tokens
    self.flowTokenVaultRef.deposit(from: <- tokenBundle.withdrawToken1())
    self.tetherVaultRef.deposit(from: <- tokenBundle.withdrawToken2())

    destroy tokenBundle
  }
}
