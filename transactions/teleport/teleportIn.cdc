import "FungibleToken"
import "TeleportedTetherToken"

transaction(amount: UFix64, target: Address, from: String, hash: String) {

  prepare(teleportAdmin: auth(BorrowValue) &Account) {

    let teleportControlRef = teleportAdmin.storage.borrow<auth(TeleportedTetherToken.TeleportControlEntitlement) &{TeleportedTetherToken.TeleportControl}>(from: /storage/teleportedTetherTokenTeleportAdmin)
      ?? panic("Could not borrow a reference to the teleport control resource")

    let vault <- teleportControlRef.teleportIn(amount: amount, from: from.decodeHex(), hash: hash)

    let receiverRef = getAccount(target).capabilities.borrow<&{FungibleToken.Receiver}>(TeleportedTetherToken.TokenPublicReceiverPath)
			?? panic("Could not borrow a reference to Receiver")

    receiverRef.deposit(from: <- vault)
  }
}