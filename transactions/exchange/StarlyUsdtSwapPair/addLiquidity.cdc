import FungibleToken from "../../../contracts/token/FungibleToken.cdc"
import StarlyToken from "../../../contracts/token/StarlyToken.cdc"
import TeleportedTetherToken from "../../../contracts/token/TeleportedTetherToken.cdc"
import StarlyUsdtSwapPair from "../../../contracts/exchange/StarlyUsdtSwapPair.cdc"

transaction(token1Amount: UFix64, token2Amount: UFix64) {
  // The Vault references that holds the tokens that are being transferred
  let starlyVault: &StarlyToken.Vault
  let usdtVault: &TeleportedTetherToken.Vault

  // The Vault reference for liquidity tokens
  let liquidityTokenRef: &StarlyUsdtSwapPair.Vault

  prepare(signer: AuthAccount) {
    self.starlyVault = signer.borrow<&StarlyToken.Vault>(from: StarlyToken.TokenStoragePath)
        ?? panic("Could not borrow a reference to Vault")

    self.usdtVault = signer.borrow<&TeleportedTetherToken.Vault>(from: TeleportedTetherToken.TokenStoragePath)
        ?? panic("Could not borrow a reference to Vault")

    if signer.borrow<&StarlyUsdtSwapPair.Vault>(from: StarlyUsdtSwapPair.TokenStoragePath) == nil {
      // Create a new StarlyUsdtSwapPair LP Token Vault and put it in storage
      signer.save(<-StarlyUsdtSwapPair.createEmptyVault(), to: StarlyUsdtSwapPair.TokenStoragePath)

      // Create a public capability to the Vault that only exposes
      // the deposit function through the Receiver interface
      signer.link<&StarlyUsdtSwapPair.Vault{FungibleToken.Receiver}>(
        StarlyUsdtSwapPair.TokenPublicReceiverPath,
        target: StarlyUsdtSwapPair.TokenStoragePath
      )

      // Create a public capability to the Vault that only exposes
      // the balance field through the Balance interface
      signer.link<&StarlyUsdtSwapPair.Vault{FungibleToken.Balance}>(
        StarlyUsdtSwapPair.TokenPublicBalancePath,
        target: StarlyUsdtSwapPair.TokenStoragePath
      )
    }

    self.liquidityTokenRef = signer.borrow<&StarlyUsdtSwapPair.Vault>(from: StarlyUsdtSwapPair.TokenStoragePath)
      ?? panic("Could not borrow a reference to Vault")
  }

  execute {
    // Withdraw tokens
    let token1Vault <- self.starlyVault.withdraw(amount: token1Amount) as! @StarlyToken.Vault
    let token2Vault <- self.usdtVault.withdraw(amount: token2Amount) as! @TeleportedTetherToken.Vault

    // Provide liquidity and get liquidity provider tokens
    let tokenBundle <- StarlyUsdtSwapPair.createTokenBundle(fromToken1: <- token1Vault, fromToken2: <- token2Vault)
    let liquidityTokenVault <- StarlyUsdtSwapPair.addLiquidity(from: <- tokenBundle)

    // Keep the liquidity provider tokens
    self.liquidityTokenRef.deposit(from: <- liquidityTokenVault)
  }
}
