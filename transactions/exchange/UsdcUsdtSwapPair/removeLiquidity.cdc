import FungibleToken from "../../../contracts/token/FungibleToken.cdc"
import FiatToken from "../../../contracts/token/FiatToken.cdc"
import TeleportedTetherToken from "../../../contracts/token/TeleportedTetherToken.cdc"
import UsdcUsdtSwapPair from "../../../contracts/exchange/UsdcUsdtSwapPair.cdc"

transaction(amount: UFix64, token1Amount: UFix64, token2Amount: UFix64) {
  // The Vault reference for liquidity tokens that are being transferred
  let liquidityTokenRef: &UsdcUsdtSwapPair.Vault

  // The Vault references to receive the liquidity tokens
  let usdcVaultRef: &FiatToken.Vault
  let tetherVaultRef: &TeleportedTetherToken.Vault

  prepare(signer: AuthAccount) {
    assert(amount == token1Amount + token2Amount: "Incosistent liquidtiy amounts")

    self.liquidityTokenRef = signer.borrow<&UsdcUsdtSwapPair.Vault>(from: UsdcUsdtSwapPair.TokenStoragePath)
      ?? panic("Could not borrow a reference to Vault")

    self.swapProxyRef = proxyHolder.borrow<&UsdcUsdtSwapPair.SwapProxy>(from: /storage/usdcUsdtSwapProxy)
      ?? panic("Could not borrow a reference to proxy holder")

    self.usdcVaultRef = signer.borrow<&FiatToken.Vault>(from: /storage/usdcVault)
      ?? panic("Could not borrow a reference to Vault")

    self.tetherVaultRef = signer.borrow<&TeleportedTetherToken.Vault>(from: TeleportedTetherToken.TokenStoragePath)
      ?? panic("Could not borrow a reference to Vault")
  }

  execute {
    // Withdraw liquidity provider tokens
    let liquidityTokenVault <- self.liquidityTokenRef.withdraw(amount: amount) as! @UsdcUsdtSwapPair.Vault

    // Take back liquidity
    let tokenBundle <- self.swapProxyRef.removeLiquidity(from: <-liquidityTokenVault, token1Amount: token1Amount, token2Amount: token2Amount)

    // Deposit liquidity tokens
    self.usdcVaultRef.deposit(from: <- tokenBundle.withdrawToken1())
    self.tetherVaultRef.deposit(from: <- tokenBundle.withdrawToken2())

    destroy tokenBundle
  }
}
