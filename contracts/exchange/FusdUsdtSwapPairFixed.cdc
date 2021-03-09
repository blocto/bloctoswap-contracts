import FungibleToken from 0xFUNGIBLETOKENADDRESS
import FUSD from 0xFUSDADDRESS
import TeleportedTetherToken from 0xTELEPORTEDUSDTADDRESS

// Exchange pair between FUSD and tUSDT
// Price is fixed at 1:1
// Token1: FUSD - Flow USD
// Token2: tUSDT - TeleportedTetherToken
pub contract FusdUsdtSwapPair {
  // Frozen flag controlled by Swap Admin
  pub var isFrozen: Bool
  
  // Total supply of FusdUsdtSwapPair liquidity token in existence
  pub var totalSupply: UFix64

  // Fee charged when performing token swap
  pub var feePercentage: UFix64

  // Used for precise calculations
  pub var shifter: UFix64

  // Controls FUSD vault
  access(contract) let token1Vault: @FUSD.Vault

  // Controls TeleportedTetherToken vault
  access(contract) let token2Vault: @TeleportedTetherToken.Vault

  // Controls FUSD vault for fees
  access(contract) let token1FeeVault: @FUSD.Vault

  // Controls TeleportedTetherToken vault for fees
  access(contract) let token2FeeVault: @TeleportedTetherToken.Vault

  // Event that is emitted when trading fee is updated
  pub event FeeUpdated(feePercentage: UFix64)

  // Event that is emitted when a swap happens
  // Side 1: from token1 to token2
  // Side 2: from token2 to token1
  pub event Trade(token1Amount: UFix64, token2Amount: UFix64, side: UInt8)

  pub resource LiquidityAdmin {
    pub fun depositToken1(from: @FUSD.Vault) {
      FusdUsdtSwapPair.token1Vault.deposit(from: <- (from as! @FungibleToken.Vault))
    }

    pub fun depositToken2(from: @TeleportedTetherToken.Vault) {
      FusdUsdtSwapPair.token2Vault.deposit(from: <- (from as! @FungibleToken.Vault))
    }

    pub fun withdrawToken1(amount: UFix64): @FUSD.Vault {
      return <- (FusdUsdtSwapPair.token1Vault.withdraw(amount: amount) as! @FUSD.Vault)
    }

    pub fun withdrawToken2(amount: UFix64): @TeleportedTetherToken.Vault {
      return <- (FusdUsdtSwapPair.token2Vault.withdraw(amount: amount) as! @TeleportedTetherToken.Vault)
    }
  }

  pub resource SwapAdmin {
    pub fun freeze() {
      FusdUsdtSwapPair.isFrozen = true
    }

    pub fun unfreeze() {
      FusdUsdtSwapPair.isFrozen = false
    }

    pub fun getFeeAmounts(): [UFix64] {
      return [
        FusdUsdtSwapPair.token1FeeVault.balance,
        FusdUsdtSwapPair.token2FeeVault.balance
      ]
    }

    pub fun withdrawToken1Fee(amount: UFix64): @FUSD.Vault {
      return <- (FusdUsdtSwapPair.token1FeeVault.withdraw(amount: amount) as! @FUSD.Vault)
    }

    pub fun withdrawToken2Fee(amount: UFix64): @TeleportedTetherToken.Vault {
      return <- (FusdUsdtSwapPair.token2FeeVault.withdraw(amount: amount) as! @TeleportedTetherToken.Vault)
    }

    pub fun updateFeePercentage(feePercentage: UFix64) {
      FusdUsdtSwapPair.feePercentage = feePercentage

      emit FeeUpdated(feePercentage: feePercentage)
    }
  }

  pub struct PoolAmounts {
    pub let token1Amount: UFix64
    pub let token2Amount: UFix64

    init(token1Amount: UFix64, token2Amount: UFix64) {
      self.token1Amount = token1Amount
      self.token2Amount = token2Amount
    }
  }

  // Check current pool amounts
  pub fun getPoolAmounts(): PoolAmounts {
    return PoolAmounts(
      token1Amount: FusdUsdtSwapPair.token1Vault.balance,
      token2Amount: FusdUsdtSwapPair.token2Vault.balance
    )
  }

  // Precise division to mitigate fixed-point division error
  pub fun preciseDiv(numerator: UFix64, denominator: UFix64): UFix64 {
    return (numerator /
        (denominator / self.shifter)
      ) / self.shifter;
  }

  // Get quote for Token1 (given) -> Token2
  pub fun quoteSwapExactToken1ForToken2(amount: UFix64): UFix64 {
    pre {
      self.token2Vault.balance >= amount: "Not enough Token2 in the pool"
    }

    // Fixed price 1:1
    return amount
  }

  // Get quote for Token1 -> Token2 (given)
  pub fun quoteSwapToken1ForExactToken2(amount: UFix64): UFix64 {
    pre {
      self.token2Vault.balance >= amount: "Not enough Token2 in the pool"
    }

    // Fixed price 1:1
    return amount
  }

  // Get quote for Token2 (given) -> Token1
  pub fun quoteSwapExactToken2ForToken1(amount: UFix64): UFix64 {
    pre {
      self.token1Vault.balance >= amount: "Not enough Token1 in the pool"
    }

    // Fixed price 1:1
    return amount
  }

  // Get quote for Token2 -> Token1 (given)
  pub fun quoteSwapToken2ForExactToken1(amount: UFix64): UFix64 {
    pre {
      self.token1Vault.balance >= amount: "Not enough Token1 in the pool"
    }

    // Fixed price 1:1
    return amount
  }

  // Swaps Token1 (FUSD) -> Token2 (tUSDT)
  pub fun swapToken1ForToken2(from: @FUSD.Vault): @TeleportedTetherToken.Vault {
    pre {
      !FusdUsdtSwapPair.isFrozen: "FusdUsdtSwapPair is frozen"
      from.balance > UFix64(0): "Empty token vault"
    }

    // collect fee if fee percentage is non-zero
    if (self.feePercentage > UFix64(0)) {
      let fee <- from.withdraw(amount: from.balance * self.feePercentage)
      self.token1FeeVault.deposit(from: <- (fee as! @FungibleToken.Vault))
    }

    let token1Amount = from.balance
    let token2Amount = self.quoteSwapExactToken1ForToken2(amount: token1Amount)

    assert(token2Amount > UFix64(0), message: "Exchanged amount too small")

    self.token1Vault.deposit(from: <- (from as! @FungibleToken.Vault))
    emit Trade(token1Amount: token1Amount, token2Amount: token2Amount, side: 1)

    return <- (self.token2Vault.withdraw(amount: token2Amount) as! @TeleportedTetherToken.Vault)
  }

  // Swap Token2 (tUSDT) -> Token1 (FUSD)
  pub fun swapToken2ForToken1(from: @TeleportedTetherToken.Vault): @FUSD.Vault {
    pre {
      !FusdUsdtSwapPair.isFrozen: "FusdUsdtSwapPair is frozen"
      from.balance > UFix64(0): "Empty token vault"
    }

    // collect fee if fee percentage is non-zero
    if (self.feePercentage > UFix64(0)) {
      let fee <- from.withdraw(amount: from.balance * self.feePercentage)
      self.token2FeeVault.deposit(from: <- (fee as! @FungibleToken.Vault))
    }

    let token2Amount = from.balance
    let token1Amount = self.quoteSwapExactToken2ForToken1(amount: from.balance)

    assert(token1Amount > UFix64(0), message: "Exchanged amount too small")

    self.token2Vault.deposit(from: <- (from as! @FungibleToken.Vault))
    emit Trade(token1Amount: token1Amount, token2Amount: token2Amount, side: 2)

    return <- (self.token1Vault.withdraw(amount: token1Amount) as! @FUSD.Vault)
  }

  init() {
    self.isFrozen = true // frozen until swap admin unfreezes
    self.totalSupply = 0.0
    self.feePercentage = 0.003 // 0.3%
    self.shifter = 10000.0

    // Setup internal FUSD vault
    self.token1Vault <- FUSD.createEmptyVault() as! @FUSD.Vault

    // Setup internal TeleportedTetherToken vault
    self.token2Vault <- TeleportedTetherToken.createEmptyVault() as! @TeleportedTetherToken.Vault

    // Setup internal FUSD vault for fees
    self.token1FeeVault <- FUSD.createEmptyVault() as! @FUSD.Vault

    // Setup internal TeleportedTetherToken vault for fees
    self.token2FeeVault <- TeleportedTetherToken.createEmptyVault() as! @TeleportedTetherToken.Vault

    let swapAdmin <- create SwapAdmin()
    self.account.save(<-swapAdmin, to: /storage/fusdUsdtPairSwapAdmin)

    let liquidityAdmin <- create LiquidityAdmin()
    self.account.save(<-liquidityAdmin, to: /storage/fusdUsdtPairLiquidityAdmin)
  }
}
