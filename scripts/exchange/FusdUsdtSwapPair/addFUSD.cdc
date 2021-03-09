import FUSD from 0xFUSDADDRESS
import FusdUsdtSwapPair from 0xFUSDUSDTSWAPPAIRADDRESS

transaction(amount: UFix64) {
  // The Vault resource that holds the tokens that are being transferred
  let sentVault: @FUSD.Vault

  // The LiquidityAdmin reference for liquidity operations 
  let liquidityAdminRef: &FusdUsdtSwapPair.LiquidityAdmin
  
  prepare(signer: AuthAccount) {
    let fusdVault = signer.borrow<&FUSD.Vault>(from: /storage/fusdVault)
      ?? panic("Could not borrow a reference to Vault")
    
    self.sentVault <- fusdVault.withdraw(amount: amount) as! @FUSD.Vault

    self.liquidityAdminRef = signer.borrow<&FusdUsdtSwapPair.LiquidityAdmin>(from: /storage/fusdUsdtPairLiquidityAdmin)
      ?? panic("Could not borrow a reference to LiquidityAdmin")
  }

  execute {
    // Add liquidity to the swap contract
    self.liquidityAdminRef.depositToken1(from: <- self.sentVault)
  }
}
 