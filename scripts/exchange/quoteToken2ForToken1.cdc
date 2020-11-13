// Script1.cdc

import FlowSwapPair from 0x04

// This script reads the Vault balances of two accounts.
pub fun main() {
  let token2Amount = 14.214
  let token1Quote = FlowSwapPair.quoteSwapExactToken2ForToken1(amount: token2Amount)

  // Use optional chaining to read and log balance fields
  log("Pay Token2:")
  log(token2Amount)
  log("Get Token1:")
  log(token1Quote)
}
