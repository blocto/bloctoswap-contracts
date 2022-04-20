import FungibleToken from "../../../contracts/token/FungibleToken.cdc"
import StarlyToken from "../../../contracts/token/StarlyToken.cdc"
import TeleportedTetherToken from "../../../contracts/token/TeleportedTetherToken.cdc"
import StarlyUsdtSwapPair from "../../../contracts/exchange/StarlyUsdtSwapPair.cdc"

transaction(amount: UFix64) {
  // The Vault reference for liquidity tokens that are being transferred
  let liquidityTokenRef: &StarlyUsdtSwapPair.Vault

  // The Vault references to receive the liquidity tokens
  let starlyVault: &StarlyToken.Vault
  let usdtVault: &TeleportedTetherToken.Vault

  prepare(signer: AuthAccount) {
    self.liquidityTokenRef = signer.borrow<&StarlyUsdtSwapPair.Vault>(from: StarlyUsdtSwapPair.TokenStoragePath)
      ?? panic("Could not borrow a reference to Vault")

    self.starlyVault = signer.borrow<&StarlyToken.Vault>(from: StarlyToken.TokenStoragePath)
        ?? panic("Could not borrow a reference to Vault")

    self.usdtVault = signer.borrow<&TeleportedTetherToken.Vault>(from: TeleportedTetherToken.TokenStoragePath)
        ?? panic("Could not borrow a reference to Vault")
  }

  execute {
    // Withdraw liquidity provider tokens
    let liquidityTokenVault <- self.liquidityTokenRef.withdraw(amount: amount) as! @StarlyUsdtSwapPair.Vault

    // Take back liquidity
    let tokenBundle <- StarlyUsdtSwapPair.removeLiquidity(from: <-liquidityTokenVault)

    // Deposit liquidity tokens
    self.starlyVault.deposit(from: <- tokenBundle.withdrawToken1())
    self.usdtVault.deposit(from: <- tokenBundle.withdrawToken2())

    destroy tokenBundle
  }
}
