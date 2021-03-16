import FungibleToken from 0xFUNGIBLETOKENADDRESS 
import FUSD from 0xFUSDADDRESS
import TeleportedTetherToken from 0xTELEPORTEDUSDTADDRESS
import FusdUsdtSwapPair from 0xFUSDUSDTSWAPPAIRADDRESS
import FusdUsdtSwapPairProxy from 0xFUSDUSDTSWAPPAIRADDRESS

transaction(amountIn: UFix64) {
  // The Vault references that holds the tokens that are being transferred
  let fusdVault: &FUSD.Vault
  let tetherVault: &TeleportedTetherToken.Vault
  
  // The proxy holder reference for access control
  let swapProxyRef: &FusdUsdtSwapPairProxy.SwapProxy

  prepare(signer: AuthAccount, proxyHolder: AuthAccount) {
    self.fusdVault = signer.borrow<&FUSD.Vault>(from: /storage/fusdVault)
      ?? panic("Could not borrow a reference to FUSD Vault")

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

    self.tetherVault = signer.borrow<&TeleportedTetherToken.Vault>(from: TeleportedTetherToken.TokenStoragePath)
      ?? panic("Could not borrow a reference to tUSDT Vault")

    self.swapProxyRef = proxyHolder.borrow<&FusdUsdtSwapPairProxy.SwapProxy>(from: FusdUsdtSwapPairProxy.SwapProxyStoragePath)
      ?? panic("Could not borrow a reference to proxy holder")
  }

  execute {    
    let token1Vault <- self.fusdVault.withdraw(amount: amountIn) as! @FUSD.Vault

    let token2Vault <- self.swapProxyRef.swapToken1ForToken2(from: <-token1Vault)

    self.tetherVault.deposit(from: <- token2Vault)
  }
}
