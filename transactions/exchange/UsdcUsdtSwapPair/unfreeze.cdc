import UsdcUsdtSwapPair from "../../../contracts/exchange/UsdcUsdtSwapPair.cdc"

transaction {
  // The Admin reference
  let adminRef: &UsdcUsdtSwapPair.Admin

  prepare(signer: AuthAccount) {
    self.adminRef = signer.borrow<&UsdcUsdtSwapPair.Admin>(from: /storage/usdcUsdtPairAdmin)
      ?? panic("Could not borrow a reference to Admin")
  }

  execute {
    self.adminRef.unfreeze()
  }
}
