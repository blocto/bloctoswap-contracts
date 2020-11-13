// Script1.cdc

import FlowSwapPair from 0x04

// This script reads the Vault balances of two accounts.
pub fun main() {
  let poolAmounts = FlowSwapPair.getPoolAmounts()

  // Use optional chaining to read and log balance fields
  log("Pool 1 Balance")
  log(poolAmounts.token1Amount)
  log("Pool 2 Balance")
  log(poolAmounts.token2Amount)
}
