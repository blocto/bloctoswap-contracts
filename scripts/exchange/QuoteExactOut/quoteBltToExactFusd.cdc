import FusdUsdtSwapPair from 0xFUSDUSDTSWAPPAIRADDRESS
import BltUsdtSwapPair from 0xBLTUSDTSWAPPAIRADDRESS

pub fun main(amount: UFix64): [UFix64] {
  let quote = FusdUsdtSwapPair.quoteSwapToken1ForExactToken2(
    amount: BltUsdtSwapPair.quoteSwapToken2ForExactToken1(amount: amount) / (1.0 - BltUsdtSwapPair.feePercentage)
  )

  let poolAmounts = BltUsdtSwapPair.getPoolAmounts()

  let currentPrice = (poolAmounts.token2Amount / poolAmounts.token1Amount)
    * (1.0 - BltUsdtSwapPair.feePercentage)

  return [quote, currentPrice]
}
