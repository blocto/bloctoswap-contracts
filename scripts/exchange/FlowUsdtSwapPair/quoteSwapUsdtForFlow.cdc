import FlowSwapPair from 0xFLOWSWAPPAIRADDRESS

// In FlowSwapPair (FLOW <> tUSDT)
// Token1: FLOW
// Token2: tUSDT
pub fun main(amount: UFix64): UFix64 {
  let quote = FlowSwapPair.quoteSwapExactToken2ForToken1(amount: amount * (1.0 - FlowSwapPair.feePercentage))

  return quote
}
