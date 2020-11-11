// This transaction is a template for a transaction
// to add a Vault resource to their account
// so that they can use the teleportedTetherToken (USDT)

import FungibleToken from 0x01
import TeleportedTetherToken from 0x02

transaction {
  prepare(teleportAdmin: AuthAccount) {
    let teleportInRef = teleportAdmin.getCapability(/private/teleportedTetherTokenTeleportIn)!
        .borrow<&TeleportedTetherToken.TeleportAdmin{TeleportedTetherToken.TeleportIn}>()
        ?? panic("Could not borrow a reference to TeleportIn")
    
    let vault <- teleportInRef.teleportIn(amount: 10.0, from: "19818f44Faf5A217F619AFF0FD487CB2a55cCa65ff".decodeHex())

    let receiverRef = getAccount(0x01).getCapability(/public/teleportedTetherTokenReceiver)!
        .borrow<&TeleportedTetherToken.Vault{FungibleToken.Receiver}>()
        ?? panic("Could not borrow a reference to Receiver")

    receiverRef.deposit(from: <- vault)
  }
}
