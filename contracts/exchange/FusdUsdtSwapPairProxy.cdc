import FUSD from 0xFUSDADDRESS
import TeleportedTetherToken from 0xTELEPORTEDUSDTADDRESS
import FusdUsdtSwapPair from 0xFUSDUSDTSWAPPAIRADDRESS

pub contract FusdUsdtSwapPairProxy {
  pub let SwapProxyStoragePath: StoragePath

  pub resource SwapProxy {
    pub fun swapToken1ForToken2(from: @FUSD.Vault): @TeleportedTetherToken.Vault {
      return <- FusdUsdtSwapPair.swapToken1ForToken2(from: <-from)
    }

    pub fun swapToken2ForToken1(from: @TeleportedTetherToken.Vault): @FUSD.Vault {
      return <- FusdUsdtSwapPair.swapToken2ForToken1(from: <-from)
    }
  }

  init() {
    self.SwapProxyStoragePath = /storage/fusdUsdtSwapPairProxy

    let proxy <- create SwapProxy()

    self.account.save(<-proxy, to: self.SwapProxyStoragePath)
  }
}
