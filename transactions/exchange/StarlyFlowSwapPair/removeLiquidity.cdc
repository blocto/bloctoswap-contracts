import FungibleToken from "../../../contracts/token/FungibleToken.cdc"
import StarlyToken from "../../../contracts/token/StarlyToken.cdc"
import FlowToken from "../../../contracts/token/FlowToken.cdc"
import StarlyFlowSwapPair from "../../../contracts/exchange/StarlyFlowSwapPair.cdc"

transaction(amount: UFix64, token1Amount: UFix64, token2Amount: UFix64) {
  // The Vault reference for liquidity tokens that are being transferred
  let liquidityTokenRef: &StarlyFlowSwapPair.Vault

  // The Vault references to receive the liquidity tokens
  let starlyVault: &StarlyToken.Vault
  let flowVault: &FlowToken.Vault

  prepare(signer: AuthAccount) {
    assert(amount == token1Amount + token2Amount, message: "Incosistent liquidtiy amounts")

    self.liquidityTokenRef = signer.borrow<&StarlyFlowSwapPair.Vault>(from: StarlyFlowSwapPair.TokenStoragePath)
      ?? panic("Could not borrow a reference to Vault")

    self.starlyVault = signer.borrow<&StarlyToken.Vault>(from: StarlyToken.TokenStoragePath)
        ?? panic("Could not borrow a reference to Vault")

    self.flowVault = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
        ?? panic("Could not borrow a reference to Vault")
  }

  execute {
    // Withdraw liquidity provider tokens
    let liquidityTokenVault <- self.liquidityTokenRef.withdraw(amount: amount) as! @StarlyFlowSwapPair.Vault

    // Take back liquidity
    let tokenBundle <- StarlyFlowSwapPair.removeLiquidity(from: <-liquidityTokenVault, token1Amount: token1Amount, token2Amount: token2Amount)

    // Deposit liquidity tokens
    self.starlyVault.deposit(from: <- tokenBundle.withdrawToken1())
    self.flowVault.deposit(from: <- tokenBundle.withdrawToken2())

    destroy tokenBundle
  }
}
