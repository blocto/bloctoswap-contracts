import StarlyUsdtSwapPair from "../../../contracts/exchange/StarlyUsdtSwapPair.cdc"

transaction {
  // The Admin reference
  let adminRef: &StarlyUsdtSwapPair.Admin

  prepare(signer: AuthAccount) {
    self.adminRef = signer.borrow<&StarlyUsdtSwapPair.Admin>(from: /storage/StarlyUsdtSwapAdmin)
      ?? panic("Could not borrow a reference to Admin")
  }

  execute {
    self.adminRef.unfreeze()
  }
}
