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
    self.flowTokenVaultRef = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
      ?? panic("Could not borrow a reference to FLOW Vault")

    if signer.borrow<&TeleportedTetherToken.Vault>(from: TeleportedTetherToken.TokenStoragePath) == nil {
      // Create a new teleportedTetherToken Vault and put it in storage
      signer.save(<-TeleportedTetherToken.createEmptyVault(), to: TeleportedTetherToken.TokenStoragePath)

      // Create a public capability to the Vault that only exposes
      // the deposit function through the Receiver interface
      signer.link<&TeleportedTetherToken.Vault{FungibleToken.Receiver}>(
        TeleportedTetherToken.TokenPublicReceiverPath,
        target: TeleportedTetherToken.TokenStoragePath
      )

      // Create a public capability to the Vault that only exposes
      // the balance field through the Balance interface
      signer.link<&TeleportedTetherToken.Vault{FungibleToken.Balance}>(
        TeleportedTetherToken.TokenPublicBalancePath,
        target: TeleportedTetherToken.TokenStoragePath
      )
    }

    self.tetherVaultRef = signer.borrow<&TeleportedTetherToken.Vault>(from: TeleportedTetherToken.TokenStoragePath)
      ?? panic("Could not borrow a reference to tUSDT Vault")

    self.swapProxyRef = proxyHolder.borrow<&FlowSwapPair.SwapProxy>(from: /storage/flowUsdtSwapProxy)
      ?? panic("Could not borrow a reference to proxy holder")
  }

  execute {    
    let token1Vault <- self.flowTokenVaultRef.withdraw(amount: amountIn) as! @FlowToken.Vault

    let token2Vault <- self.swapProxyRef.swapToken1ForToken2(from: <-token1Vault)

    self.tetherVaultRef.deposit(from: <- token2Vault)
  }
}
