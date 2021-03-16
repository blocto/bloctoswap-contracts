import FlowToken from 0xFLOWTOKENADDRESS
import TeleportedTetherToken from 0xTELEPORTEDUSDTADDRESS
import FlowSwapPair from 0xFLOWSWAPPAIRADDRESS

pub contract FlowSwapPairProxy {
  pub let SwapProxyStoragePath: StoragePath

  pub resource SwapProxy {
    pub fun swapToken1ForToken2(from: @FlowToken.Vault): @TeleportedTetherToken.Vault {
      return <- FlowSwapPair.swapToken1ForToken2(from: <-from)
    }

    pub fun swapToken2ForToken1(from: @TeleportedTetherToken.Vault): @FlowToken.Vault {
      return <- FlowSwapPair.swapToken2ForToken1(from: <-from)
    }

    pub fun addLiquidity(from: @FlowSwapPair.TokenBundle): @FlowSwapPair.Vault {
      return <- FlowSwapPair.addLiquidity(from: <-from)
    }

    pub fun removeLiquidity(from: @FlowSwapPair.Vault): @FlowSwapPair.TokenBundle {
      return <- FlowSwapPair.removeLiquidity(from: <-from)
    }
  }

  init() {
    self.SwapProxyStoragePath = /storage/flowSwapProxy

    let proxy <- create SwapProxy()

    self.account.save(<-proxy, to: self.SwapProxyStoragePath)
  }
}
