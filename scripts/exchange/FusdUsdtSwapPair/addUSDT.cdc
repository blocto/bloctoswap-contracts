import TeleportedTetherToken from 0xTELEPORTEDUSDTADDRESS
import FusdUsdtSwapPair from 0xFUSDUSDTSWAPPAIRADDRESS

transaction(amount: UFix64) {
  // The Vault resource that holds the tokens that are being transferred
  let sentVault: @TeleportedTetherToken.Vault

  // The LiquidityAdmin reference for liquidity operations 
  let liquidityAdminRef: &FusdUsdtSwapPair.LiquidityAdmin
  
  prepare(signer: AuthAccount) {
    let usdtVault = signer.borrow<&TeleportedTetherToken.Vault>(from: /storage/teleportedTetherTokenVault)
      ?? panic("Could not borrow a reference to Vault")
    
    self.sentVault <- usdtVault.withdraw(amount: amount) as! @TeleportedTetherToken.Vault

    self.liquidityAdminRef = signer.borrow<&FusdUsdtSwapPair.LiquidityAdmin>(from: /storage/fusdUsdtPairLiquidityAdmin)
      ?? panic("Could not borrow a reference to LiquidityAdmin")
  }

  execute {
    // Add liquidity to the swap contract
    self.liquidityAdminRef.depositToken2(from: <- self.sentVault)
  }
}
 