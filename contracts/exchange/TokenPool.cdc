import FungibleToken from 0xFUNGIBLETOKENADDRESS
import FlowToken from 0xFLOWTOKENADDRESS
import TeleportedTetherToken from 0xTELEPORTEDTETHERTOKENADDRESS
import FlowSwapPair from 0xFLOWSWAPPAIRADDRESS

// Perpetual pool between FlowToken and TeleportedTetherToken
// Token1: FlowToken
// Token2: TeleportedTetherToken
pub contract TokenPool {
  // Total supply of FlowSwapExchange liquidity token in existence
  pub var totalSupply: UFix64

  // Virtual FlowToken amount for price calculation
  pub var virtualToken1Amount: UFix64

  // Virtual TeleportedTetherToken amount for price calculation
  pub var virtualToken2Amount: UFix64

  // Price to buy back FLOW
  pub var buyBackPrice: UFix64

  // Used for precise calculations
  pub var shifter: UFix64

  // Percentage to donate to FlowSwapPair pool
  pub var donationRatio: UFix64

  // Address of the LP token receiver
  pub var lpTokenReceiver: Address

  // Controls FlowToken vault
  access(contract) let token1Vault: @FlowToken.Vault

  // Controls TeleportedTetherToken vault
  access(contract) let token2Vault: @TeleportedTetherToken.Vault

  // Event that is emitted when a swap happens
  // Side 1: from token1 to token2
  // Side 2: from token2 to token1
  pub event Trade(token1Amount: UFix64, token2Amount: UFix64, side: UInt8)

  pub resource Admin {
    pub fun addLiquidity(from: @FlowSwapPair.TokenBundle) {
      let token1Vault <- from.withdrawToken1()
      let token2Vault <- from.withdrawToken2()

      TokenPool.token1Vault.deposit(from: <- token1Vault)
      TokenPool.token2Vault.deposit(from: <- token2Vault)

      destroy from
    }

    pub fun removeLiquidity(amountToken1: UFix64, amountToken2: UFix64): @FlowSwapPair.TokenBundle {
      let token1Vault <- TokenPool.token1Vault.withdraw(amount: amountToken1) as! @FlowToken.Vault
      let token2Vault <- TokenPool.token2Vault.withdraw(amount: amountToken2) as! @TeleportedTetherToken.Vault

      let tokenBundle <- FlowSwapPair.createTokenBundle(fromToken1: <- token1Vault, fromToken2: <- token2Vault)
      return <- tokenBundle
    }

    pub fun updateVirtualAmounts(amountToken1: UFix64, amountToken2: UFix64) {
      TokenPool.virtualToken1Amount = amountToken1
      TokenPool.virtualToken2Amount = amountToken2
    }

    pub fun updateBuyBackPrice(price: UFix64) {
      TokenPool.buyBackPrice = price
    }

    pub fun updateDonationRatio(donationRatio: UFix64) {
      TokenPool.donationRatio = donationRatio
    }
  }

  // Check current pool amounts (virtual pool)
  pub fun getPoolAmounts(): FlowSwapPair.PoolAmounts {
    return FlowSwapPair.PoolAmounts(token1Amount: TokenPool.virtualToken1Amount, token2Amount: virtualToken2Amount)
  }

  // Check current pool amounts
  pub fun getActualPoolAmounts(): FlowSwapPair.PoolAmounts {
    return FlowSwapPair.PoolAmounts(token1Amount: TokenPool.token1Vault.balance, token2Amount: TokenPool.token2Vault.balance)
  }

  // Precise division to mitigate fixed-point division error
  pub fun preciseDiv(numerator: UFix64, denominator: UFix64) {
    return
      (numerator /
        (denominator / self.shifter)
      ) / self.shifter;
  }

  // Get quote for Token1 (given) -> Token2
  pub fun quoteSwapExactToken1ForToken2(amount: UFix64): UFix64 {
    let quote = amount * self.buyBackPrice

    assert(self.token2Vault.balance > quote, message: "Not enough Token2 in the pool")

    return quote
  }

  // Get quote for Token1 -> Token2 (given)
  pub fun quoteSwapToken1ForExactToken2(amount: UFix64): UFix64 {
    assert(self.token2Vault.balance > amount, message: "Not enough Token2 in the pool")

    return self.preciseDiv(amount, self.buyBackPrice)
  }

  // Get quote for Token2 (given) -> Token1
  pub fun quoteSwapExactToken2ForToken1(amount: UFix64): UFix64 {
    let poolAmounts = self.getPoolAmounts()

    // token1Amount * token2Amount = token1Amount' * token2Amount' = (token2Amount + amount) * (token1Amount - quote)
    let quote = self.preciseDiv(poolAmounts.token1Amount * amount, poolAmounts.token2Amount + amount);

    assert(self.token1Vault.balance > quote, message: "Not enough Token1 in the pool")

    return quote
  }

  // Get quote for Token2 -> Token1 (given)
  pub fun quoteSwapToken2ForExactToken1(amount: UFix64): UFix64 {
    let poolAmounts = self.getPoolAmounts()

    assert(poolAmounts.token1Amount > amount, message: "Not enough Token1 (virtual) in the pool")
    assert(self.token1Vault.balance > amount, message: "Not enough Token1 in the pool")

    // token1Amount * token2Amount = token1Amount' * token2Amount' = (token2Amount + quote) * (token1Amount - amount)
    let quote = self.preciseDiv(poolAmounts.token2Amount * amount, poolAmounts.token1Amount - amount);

    return quote
  }

  // Swaps Token1 (FLOW) -> Token2 (tUSDT)
  pub fun swapToken1ForToken2(from: @FlowToken.Vault): @TeleportedTetherToken.Vault {
    pre {
      from.balance > UFix64(0): "Empty token vault"
    }

    // Calculate amount from pricing curve
    // A fee portion is taken from the final amount
    let token1Amount = from.balance
    let token2Amount = self.quoteSwapExactToken1ForToken2(amount: token1Amount)

    assert(token2Amount > UFix64(0), message: "Exchanged amount too small")

    self.token1Vault.deposit(from: <- (from as! @FungibleToken.Vault))
    emit Trade(token1Amount: token1Amount, token2Amount: token2Amount, side: 1)

    return <- (self.token2Vault.withdraw(amount: token2Amount) as! @TeleportedTetherToken.Vault)
  }

  // Swap Token2 (tUSDT) -> Token1 (FLOW)
  pub fun swapToken2ForToken1(from: @TeleportedTetherToken.Vault): @FlowToken.Vault {
    pre {
      from.balance > UFix64(0): "Empty token vault"
    }

    // Calculate amount from pricing curve
    // A fee portion is taken from the final amount
    let token2Amount = from.balance
    let token1Amount = self.quoteSwapExactToken2ForToken1(amount: token2Amount)

    assert(token1Amount > UFix64(0), message: "Exchanged amount too small")

    self.token2Vault.deposit(from: <- (from as! @FungibleToken.Vault))
    emit Trade(token1Amount: token1Amount, token2Amount: token2Amount, side: 2)

    // Update virtual pool
    self.virtualToken2Amount += token2Amount
    self.virtualToken1Amount -= token1Amount

    return <- (self.token1Vault.withdraw(amount: token1Amount) as! @FlowToken.Vault)
  }

  init() {
    self.virtualToken1Amount = 100000.0
    self.virtualToken2Amount = 38000.0
    self.buyBackPrice = 0.001
    self.shifter = 10000.0
    self.donationRatio = 0.1
    self.lpTokenReceiver = 0xFLOWSWAPPAIRADDRESS

    // Setup internal FlowToken vault
    self.token1Vault <- FlowToken.createEmptyVault() as! @FlowToken.Vault

    // Setup internal TeleportedTetherToken vault
    self.token2Vault <- TeleportedTetherToken.createEmptyVault() as! @TeleportedTetherToken.Vault

    let admin <- create Admin()
    self.account.save(<-admin, to: /storage/tokenPoolAdmin)
  }
}
