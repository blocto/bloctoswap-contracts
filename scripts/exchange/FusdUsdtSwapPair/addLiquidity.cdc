import FungibleToken from 0xFUNGIBLETOKENADDRESS
import FUSD from 0xFUSDADDRESS
import TeleportedTetherToken from 0xTELEPORTEDUSDTADDRESS
import FusdUsdtSwapPair from 0xFUSDUSDTSWAPPAIRADDRESS

transaction(token1Amount: UFix64, token2Amount: UFix64) {
  // The Vault references that holds the tokens that are being transferred
  let fusdVault: &FUSD.Vault
  let tetherVault: &TeleportedTetherToken.Vault

  // The Vault reference for liquidity tokens
  let liquidityTokenRef: &FusdUsdtSwapPair.Vault

  prepare(signer: AuthAccount) {
    self.fusdVault = signer.borrow<&FUSD.Vault>(from: /storage/fusdVault)
        ?? panic("Could not borrow a reference to Vault")

    self.tetherVault = signer.borrow<&TeleportedTetherToken.Vault>(from: /storage/teleportedTetherTokenVault)
        ?? panic("Could not borrow a reference to Vault")

    if signer.borrow<&FusdUsdtSwapPair.Vault>(from: FusdUsdtSwapPair.TokenStoragePath) == nil {
      // Create a new flowToken Vault and put it in storage
      signer.save(<-FusdUsdtSwapPair.createEmptyVault(), to: FusdUsdtSwapPair.TokenStoragePath)

      // Create a public capability to the Vault that only exposes
      // the deposit function through the Receiver interface
      signer.link<&FusdUsdtSwapPair.Vault{FungibleToken.Receiver}>(
        FusdUsdtSwapPair.TokenPublicReceiverPath,
        target: FusdUsdtSwapPair.TokenStoragePath
      )

      // Create a public capability to the Vault that only exposes
      // the balance field through the Balance interface
      signer.link<&FusdUsdtSwapPair.Vault{FungibleToken.Balance}>(
        FusdUsdtSwapPair.TokenPublicBalancePath,
        target: FusdUsdtSwapPair.TokenStoragePath
      )
    }

    self.liquidityTokenRef = signer.borrow<&FusdUsdtSwapPair.Vault>(from: FusdUsdtSwapPair.TokenStoragePath)
        ?? panic("Could not borrow a reference to Vault")
  }

  execute {
    // Withdraw tokens
    let token1Vault <- self.fusdVault.withdraw(amount: token1Amount) as! @FUSD.Vault
    let token2Vault <- self.tetherVault.withdraw(amount: token2Amount) as! @TeleportedTetherToken.Vault

    // Provide liquidity and get liquidity provider tokens
    let tokenBundle <- FusdUsdtSwapPair.createTokenBundle(fromToken1: <- token1Vault, fromToken2: <- token2Vault)
    let liquidityTokenVault <- FusdUsdtSwapPair.addLiquidity(from: <- tokenBundle)

    // Keep the liquidity provider tokens
    self.liquidityTokenRef.deposit(from: <- liquidityTokenVault)
  }
}
