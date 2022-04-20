import SprtUsdtSwapPair from "../../../contracts/exchange/SprtUsdtSwapPair.cdc"

transaction {
  // The Admin reference
  let adminRef: &SprtUsdtSwapPair.Admin

  prepare(signer: AuthAccount) {
    self.adminRef = signer.borrow<&SprtUsdtSwapPair.Admin>(from: /storage/SprtUsdtSwapAdmin)
      ?? panic("Could not borrow a reference to Admin")
  }

  execute {
    self.adminRef.freeze()
  }
}
