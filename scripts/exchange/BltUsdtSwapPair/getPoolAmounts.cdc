import BltUsdtSwapPair from "../../../contracts/exchange/BltUsdtSwapPair.cdc"

pub fun main(): BltUsdtSwapPair.PoolAmounts {
  return BltUsdtSwapPair.getPoolAmounts()
}
