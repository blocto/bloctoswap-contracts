import FungibleToken from 0xFUNGIBLETOKENADDRESS
import FlowToken from 0xFLOWTOKENADDRESS
import TeleportedTetherToken from 0xTELEPORTEDUSDTADDRESS
import FlowSwapPair from 0xFLOWSWAPPAIRADDRESS

transaction(amountIn: UFix64) {
  // The Vault references that holds the tokens that are being transferred
  let flowTokenVaultRef: &FlowToken.Vault
  let tetherVaultRef: &TeleportedTetherToken.Vault

  // The proxy holder reference for access control
  let swapProxyRef: &FlowSwapPair.SwapProxy

  prepare(signer: AuthAccount, proxyHolder: AuthAccount) {
    self.tetherVaultRef = signer.borrow<&TeleportedTetherToken.Vault>(from: TeleportedTetherToken.TokenStoragePath)
      ?? panic("Could not borrow a reference to tUSDT Vault")

    self.flowTokenVaultRef = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
      ?? panic("Could not borrow a reference to FLOW Vault")

    self.swapProxyRef = proxyHolder.borrow<&FlowSwapPair.SwapProxy>(from: /storage/flowUsdtSwapProxy)
      ?? panic("Could not borrow a reference to proxy holder")
  }

  execute {    
    let token2Vault <- self.tetherVaultRef.withdraw(amount: amountIn) as! @TeleportedTetherToken.Vault

    let token1Vault <- self.swapProxyRef.swapToken2ForToken1(from: <-token2Vault)

    self.flowTokenVaultRef.deposit(from: <- token1Vault)
  }
}
