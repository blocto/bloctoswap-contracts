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

    pub fun addLiquidity(from: @FusdUsdtSwapPair.TokenBundle): @FusdUsdtSwapPair.Vault {
      return <- FusdUsdtSwapPair.addLiquidity(from: <-from)
    }

    pub fun removeLiquidity(from: @FusdUsdtSwapPair.Vault, token1Amount: UFix64, token2Amount: UFix64): @FusdUsdtSwapPair.TokenBundle {
      return <- FusdUsdtSwapPair.removeLiquidity(from: <-from, token1Amount: token1Amount, token2Amount: token2Amount)
    }
  }

  init() {
    self.SwapProxyStoragePath = /storage/fusdUsdtSwapPairProxy

    let proxy <- create SwapProxy()

    self.account.save(<-proxy, to: self.SwapProxyStoragePath)
  }
}
