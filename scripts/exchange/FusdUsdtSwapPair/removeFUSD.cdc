import FUSD from 0xFUSDADDRESS
import FusdUsdtSwapPair from 0xFUSDUSDTSWAPPAIRADDRESS

transaction(amount: UFix64) {
  // The Vault reference for depositing removed liquidity
  let vaultRef: &FUSD.Vault

  // The LiquidityAdmin reference for liquidity operations 
  let liquidityAdminRef: &FusdUsdtSwapPair.LiquidityAdmin
  
  prepare(signer: AuthAccount) {
    self.vaultRef = signer.borrow<&FUSD.Vault>(from: /storage/fusdVault)
      ?? panic("Could not borrow a reference to Vault")

    self.liquidityAdminRef = signer.borrow<&FusdUsdtSwapPair.LiquidityAdmin>(from: /storage/fusdUsdtPairLiquidityAdmin)
      ?? panic("Could not borrow a reference to LiquidityAdmin")
  }

  execute {
    // Remove liquidity from the swap contract
    self.vaultRef.deposit(from: <- self.liquidityAdminRef.withdrawToken1(amount: amount))
  }
}
 