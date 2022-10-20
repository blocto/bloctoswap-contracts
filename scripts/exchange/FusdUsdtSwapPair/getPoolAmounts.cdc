import FusdUsdtSwapPair from "../../../contracts/exchange/FusdUsdtSwapPair.cdc"

pub fun main(): FusdUsdtSwapPair.PoolAmounts {
  return FusdUsdtSwapPair.getPoolAmounts()
}
