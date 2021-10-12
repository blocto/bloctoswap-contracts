import BltUsdtSwapPair from 0xBLTUSDTSWAPPAIRADDRESS
import FusdUsdtSwapPair from 0xFUSDUSDTSWAPPAIRADDRESS

pub fun main(amount: UFix64): [UFix64] {
  let quoteUsdt = BltUsdtSwapPair.quoteSwapExactToken1ForToken2(amount: amount * (1.0 - BltUsdtSwapPair.feePercentage))
  let quote = FusdUsdtSwapPair.quoteSwapExactToken2ForToken1(amount: quoteUsdt)
  
  let poolAmounts = BltUsdtSwapPair.getPoolAmounts()

  let currentPrice = (poolAmounts.token2Amount / poolAmounts.token1Amount)
    * (1.0 - BltUsdtSwapPair.feePercentage)

  return [quote, currentPrice]
}
