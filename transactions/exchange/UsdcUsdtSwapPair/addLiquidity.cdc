import FungibleToken from "../../../contracts/token/FungibleToken.cdc"
import FiatToken from "../../../contracts/token/FiatToken.cdc"
import TeleportedTetherToken from "../../../contracts/token/TeleportedTetherToken.cdc"
import UsdcUsdtSwapPair from "../../../contracts/exchange/UsdcUsdtSwapPair.cdc"

transaction(token1Amount: UFix64, token2Amount: UFix64) {
  // The Vault references that holds the tokens that are being transferred
  let usdcVault: &FiatToken.Vault
  let tetherVault: &TeleportedTetherToken.Vault

  // The Vault reference for liquidity tokens
  let liquidityTokenRef: &UsdcUsdtSwapPair.Vault

  prepare(signer: AuthAccount, proxyHolder: AuthAccount) {
    self.usdcVault = signer.borrow<&FiatToken.Vault>(from: FiatToken.VaultStoragePath)
        ?? panic("Could not borrow a reference to Vault")

    self.tetherVault = signer.borrow<&TeleportedTetherToken.Vault>(from: /storage/teleportedTetherTokenVault)
        ?? panic("Could not borrow a reference to Vault")

    if signer.borrow<&UsdcUsdtSwapPair.Vault>(from: UsdcUsdtSwapPair.TokenStoragePath) == nil {
      // Create a new flowToken Vault and put it in storage
      signer.save(<-UsdcUsdtSwapPair.createEmptyVault(), to: UsdcUsdtSwapPair.TokenStoragePath)

      // Create a public capability to the Vault that only exposes
      // the deposit function through the Receiver interface
      signer.link<&UsdcUsdtSwapPair.Vault{FungibleToken.Receiver}>(
        UsdcUsdtSwapPair.TokenPublicReceiverPath,
        target: UsdcUsdtSwapPair.TokenStoragePath
      )

      // Create a public capability to the Vault that only exposes
      // the balance field through the Balance interface
      signer.link<&UsdcUsdtSwapPair.Vault{FungibleToken.Balance}>(
        UsdcUsdtSwapPair.TokenPublicBalancePath,
        target: UsdcUsdtSwapPair.TokenStoragePath
      )
    }

    self.liquidityTokenRef = signer.borrow<&UsdcUsdtSwapPair.Vault>(from: UsdcUsdtSwapPair.TokenStoragePath)
      ?? panic("Could not borrow a reference to Vault")
  }

  execute {
    // Withdraw tokens
    let token1Vault <- self.usdcVault.withdraw(amount: token1Amount) as! @FiatToken.Vault
    let token2Vault <- self.tetherVault.withdraw(amount: token2Amount) as! @TeleportedTetherToken.Vault

    // Provide liquidity and get liquidity provider tokens
    let tokenBundle <- UsdcUsdtSwapPair.createTokenBundle(fromToken1: <- token1Vault, fromToken2: <- token2Vault)
    let liquidityTokenVault <- UsdcUsdtSwapPair.addLiquidity(from: <- tokenBundle)

    // Keep the liquidity provider tokens
    self.liquidityTokenRef.deposit(from: <- liquidityTokenVault)
  }
}
