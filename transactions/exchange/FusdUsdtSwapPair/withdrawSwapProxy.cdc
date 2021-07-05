import FusdUsdtSwapPair from 0xFUSDUSDTSWAPPAIRADDRESS

transaction {
  prepare(proxyHolder: AuthAccount) {
    let swapProxyHolder = proxyHolder
      .borrow<&FusdUsdtSwapPair.SwapProxyHolder>(from: /storage/fusdUsdtSwapProxyHolder)
      ?? panic("Could not borrow a reference to SwapProxyHolder")

    let swapProxy <- swapProxyHolder.withdrawSwapProxy()

    proxyHolder.save(<-swapProxy, to: /storage/fusdUsdtSwapProxy)
  }
}
