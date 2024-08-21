import "FungibleToken"
import "TeleportedTetherToken"

transaction(amount: UFix64, to: Address) {

  // The Vault resource that holds the tokens that are being transferred
  let sentVault: @{FungibleToken.Vault}

  prepare(signer: auth(BorrowValue) &Account) {

    // Get a reference to the signer's stored vault
    let vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &TeleportedTetherToken.Vault>(from: TeleportedTetherToken.TokenStoragePath)
      ?? panic("Could not borrow reference to the owner's Vault!")

    // Withdraw tokens from the signer's stored vault
    self.sentVault <- vaultRef.withdraw(amount: amount)
  }

  execute {

    // Get the recipient's public account object
    let recipient = getAccount(to)

    // Get a reference to the recipient's Receiver
    let receiverRef = recipient.capabilities.borrow<&{FungibleToken.Receiver}>(TeleportedTetherToken.TokenPublicReceiverPath)
      ?? panic("Could not borrow receiver reference to the recipient's Vault")

    // Deposit the withdrawn tokens in the recipient's receiver
    receiverRef.deposit(from: <- self.sentVault)
  }
}