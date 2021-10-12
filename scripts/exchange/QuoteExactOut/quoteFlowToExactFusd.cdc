import FlowSwapPair from 0xFLOWSWAPPAIRADDRESS
import FusdUsdtSwapPair from 0xFUSDUSDTSWAPPAIRADDRESS

pub fun main(amount: UFix64): [UFix64] {
  let quote = FlowSwapPair.quoteSwapToken1ForExactToken2(
    amount: FusdUsdtSwapPair.quoteSwapToken2ForExactToken1(amount: amount)
  ) / (1.0 - FlowSwapPair.feePercentage)

  let poolAmounts1 = FlowSwapPair.getPoolAmounts()

  let currentPrice = (poolAmounts1.token2Amount / poolAmounts1.token1Amount)
    * (1.0 - FlowSwapPair.feePercentage)

  return [quote, currentPrice]
}
