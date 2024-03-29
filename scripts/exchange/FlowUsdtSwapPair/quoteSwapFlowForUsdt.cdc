import FlowSwapPair from "../../../contracts/exchange/FlowSwapPair.cdc"

// In FlowSwapPair (FLOW <> tUSDT)
// Token1: FLOW
// Token2: tUSDT
pub fun main(amount: UFix64): UFix64 {
  let quote = FlowSwapPair.quoteSwapExactToken1ForToken2(amount: amount * (1.0 - FlowSwapPair.feePercentage))

  return quote
}
