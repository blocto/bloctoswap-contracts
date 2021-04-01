import FusdUsdtSwapPair from 0xFUSDUSDTSWAPPAIRADDRESS

transaction(to: Address) {
  let proxy: @FusdUsdtSwapPair.SwapProxy

  prepare(swapContractAccount: AuthAccount) {
    let adminRef = swapContractAccount.borrow<&FusdUsdtSwapPair.Admin>(from: /storage/fusdUsdtPairAdmin)
      ?? panic("Could not borrow a reference to Admin")

    self.proxy <- adminRef.createSwapProxy()
  }

  execute {
    // Get the recipient's public account object
    let recipient = getAccount(to)

    let receiverRef = recipient
      .getCapability(/public/fusdUsdtSwapProxyReceiver)
      .borrow<&FusdUsdtSwapPair.SwapProxyHolder{FusdUsdtSwapPair.SwapProxyReceiver}>()
			?? panic("Could not borrow receiver reference to the recipient's SwapProxyHolder")
    
    receiverRef.depositSwapProxy(from: <- self.proxy)
  }
}
