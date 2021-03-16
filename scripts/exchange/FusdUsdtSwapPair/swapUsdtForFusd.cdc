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
    self.tetherVault = signer.borrow<&TeleportedTetherToken.Vault>(from: TeleportedTetherToken.TokenStoragePath)
      ?? panic("Could not borrow a reference to tUSDT Vault")

    if signer.borrow<&FUSD.Vault>(from: /storage/fusdVault) == nil {
      // Create a new FUSD Vault and put it in storage
      signer.save(<-FUSD.createEmptyVault(), to: /storage/fusdVault)

      // Create a public capability to the Vault that only exposes
      // the deposit function through the Receiver interface
      signer.link<&FUSD.Vault{FungibleToken.Receiver}>(
        /public/fusdReceiver,
        target: /storage/fusdVault
      )

      // Create a public capability to the Vault that only exposes
      // the balance field through the Balance interface
      signer.link<&FUSD.Vault{FungibleToken.Balance}>(
        /public/fusdBalance,
        target: /storage/fusdVault
      )
    }

    self.fusdVault = signer.borrow<&FUSD.Vault>(from: /storage/fusdVault)
      ?? panic("Could not borrow a reference to FUSD Vault")

    self.swapProxyRef = proxyHolder.borrow<&FusdUsdtSwapPairProxy.SwapProxy>(from: FusdUsdtSwapPairProxy.SwapProxyStoragePath)
      ?? panic("Could not borrow a reference to proxy holder")
  }

  execute {    
    let token2Vault <- tetherVault.withdraw(amount: amountIn) as! @TeleportedTetherToken.Vault

    let token1Vault <- self.swapProxyRef.swapToken2ForToken1(from: <-token2Vault)

    self.fusdVault.deposit(from: <- token1Vault)
  }
}
