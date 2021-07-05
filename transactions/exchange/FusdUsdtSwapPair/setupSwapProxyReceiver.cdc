import FusdUsdtSwapPair from 0xFUSDUSDTSWAPPAIRADDRESS

transaction {
  prepare(proxyHolder: AuthAccount) {
    let swapProxyHolder <- FusdUsdtSwapPair.createSwapProxyHolder()

    proxyHolder.save(<-swapProxyHolder, to: /storage/fusdUsdtSwapProxyHolder)

    // create new receiver that marks received tokens as unlocked
    proxyHolder.link<&FusdUsdtSwapPair.SwapProxyHolder{FusdUsdtSwapPair.SwapProxyReceiver}>(
      /public/fusdUsdtSwapProxyReceiver,
      target: /storage/fusdUsdtSwapProxyHolder
    )
  }
}
