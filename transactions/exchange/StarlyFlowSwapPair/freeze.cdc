import StarlyFlowSwapPair from "../../../contracts/exchange/StarlyFlowSwapPair.cdc"

transaction {
  // The Admin reference
  let adminRef: &StarlyFlowSwapPair.Admin

  prepare(signer: AuthAccount) {
    self.adminRef = signer.borrow<&StarlyFlowSwapPair.Admin>(from: /storage/StarlyTokenFlowSwapAdmin)
      ?? panic("Could not borrow a reference to Admin")
  }

  execute {
    self.adminRef.freeze()
  }
}
