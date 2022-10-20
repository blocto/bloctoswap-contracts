import UsdcUsdtSwapPair from "../../../contracts/exchange/UsdcUsdtSwapPair.cdc"

pub fun main(): UsdcUsdtSwapPair.PoolAmounts {
  return UsdcUsdtSwapPair.getPoolAmounts()
}
