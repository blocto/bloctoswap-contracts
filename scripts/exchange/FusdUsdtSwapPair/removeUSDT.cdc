import TeleportedTetherToken from 0xTELEPORTEDUSDTADDRESS
import FusdUsdtSwapPair from 0xFUSDUSDTSWAPPAIRADDRESS

transaction(amount: UFix64) {
  // The Vault reference for depositing removed liquidity
  let vaultRef: &TeleportedTetherToken.Vault

  // The LiquidityAdmin reference for liquidity operations 
  let liquidityAdminRef: &FusdUsdtSwapPair.LiquidityAdmin
  
  prepare(signer: AuthAccount) {
    self.vaultRef = signer.borrow<&TeleportedTetherToken.Vault>(from: /storage/teleportedTetherTokenVault)
      ?? panic("Could not borrow a reference to Vault")

    self.liquidityAdminRef = signer.borrow<&FusdUsdtSwapPair.LiquidityAdmin>(from: /storage/fusdUsdtPairLiquidityAdmin)
      ?? panic("Could not borrow a reference to LiquidityAdmin")
  }

  execute {
    // Remove liquidity from the swap contract
    self.vaultRef.deposit(from: <- self.liquidityAdminRef.withdrawToken2(amount: amount))
  }
}
 