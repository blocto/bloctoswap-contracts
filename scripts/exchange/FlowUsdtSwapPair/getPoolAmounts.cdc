import FlowSwapPair from "../../../contracts/exchange/FlowSwapPair.cdc"

pub fun main(): FlowSwapPair.PoolAmounts {
  return FlowSwapPair.getPoolAmounts()
}
