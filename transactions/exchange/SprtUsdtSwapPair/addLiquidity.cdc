import FungibleToken from "../../../contracts/token/FungibleToken.cdc"
import TeleportedSportiumToken from "../../../contracts/token/TeleportedSportiumToken.cdc"
import TeleportedTetherToken from "../../../contracts/token/TeleportedTetherToken.cdc"
import SprtUsdtSwapPair from "../../../contracts/exchange/SprtUsdtSwapPair.cdc"

transaction(token1Amount: UFix64, token2Amount: UFix64) {
  // The Vault references that holds the tokens that are being transferred
  let starlyVault: &TeleportedSportiumToken.Vault
  let usdtVault: &TeleportedTetherToken.Vault

  // The Vault reference for liquidity tokens
  let liquidityTokenRef: &SprtUsdtSwapPair.Vault

  prepare(signer: AuthAccount) {
    self.starlyVault = signer.borrow<&TeleportedSportiumToken.Vault>(from: TeleportedSportiumToken.TokenStoragePath)
        ?? panic("Could not borrow a reference to Vault")

    self.usdtVault = signer.borrow<&TeleportedTetherToken.Vault>(from: TeleportedTetherToken.TokenStoragePath)
        ?? panic("Could not borrow a reference to Vault")

    if signer.borrow<&SprtUsdtSwapPair.Vault>(from: SprtUsdtSwapPair.TokenStoragePath) == nil {
      // Create a new SprtUsdtSwapPair LP Token Vault and put it in storage
      signer.save(<-SprtUsdtSwapPair.createEmptyVault(), to: SprtUsdtSwapPair.TokenStoragePath)

      // Create a public capability to the Vault that only exposes
      // the deposit function through the Receiver interface
      signer.link<&SprtUsdtSwapPair.Vault{FungibleToken.Receiver}>(
        SprtUsdtSwapPair.TokenPublicReceiverPath,
        target: SprtUsdtSwapPair.TokenStoragePath
      )

      // Create a public capability to the Vault that only exposes
      // the balance field through the Balance interface
      signer.link<&SprtUsdtSwapPair.Vault{FungibleToken.Balance}>(
        SprtUsdtSwapPair.TokenPublicBalancePath,
        target: SprtUsdtSwapPair.TokenStoragePath
      )
    }

    self.liquidityTokenRef = signer.borrow<&SprtUsdtSwapPair.Vault>(from: SprtUsdtSwapPair.TokenStoragePath)
      ?? panic("Could not borrow a reference to Vault")
  }

  execute {
    // Withdraw tokens
    let token1Vault <- self.starlyVault.withdraw(amount: token1Amount) as! @TeleportedSportiumToken.Vault
    let token2Vault <- self.usdtVault.withdraw(amount: token2Amount) as! @TeleportedTetherToken.Vault

    // Provide liquidity and get liquidity provider tokens
    let tokenBundle <- SprtUsdtSwapPair.createTokenBundle(fromToken1: <- token1Vault, fromToken2: <- token2Vault)
    let liquidityTokenVault <- SprtUsdtSwapPair.addLiquidity(from: <- tokenBundle)

    // Keep the liquidity provider tokens
    self.liquidityTokenRef.deposit(from: <- liquidityTokenVault)
  }
}
