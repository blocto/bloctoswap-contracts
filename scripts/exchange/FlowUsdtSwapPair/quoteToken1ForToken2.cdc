// Script1.cdc

import FlowSwapPair from 0x04

// This script reads the Vault balances of two accounts.
pub fun main() {
  let token1Amount = 20.0
  let token2Quote = FlowSwapPair.quoteSwapExactToken1ForToken2(amount: token1Amount)

  // Use optional chaining to read and log balance fields
  log("Pay Token1:")
  log(token1Amount)
  log("Get Token2:")
  log(token2Quote)
}
