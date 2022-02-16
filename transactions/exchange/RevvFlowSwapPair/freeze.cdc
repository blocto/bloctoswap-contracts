import RevvFlowSwapPair from "../../../contracts/exchange/RevvFlowSwapPair.cdc"

transaction {
  // The Admin reference
  let adminRef: &RevvFlowSwapPair.Admin

  prepare(signer: AuthAccount) {
    self.adminRef = signer.borrow<&RevvFlowSwapPair.Admin>(from: /storage/revvFlowSwapAdmin)
      ?? panic("Could not borrow a reference to Admin")
  }

  execute {
    self.adminRef.freeze()
  }
}
