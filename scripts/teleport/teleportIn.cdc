import FungibleToken from 0x9a0766d93b6608b7
import TeleportedTetherToken from 0xf4772588268a160f

transaction(amount: UFix64, target: Address, from: String, hash: String) {
  prepare(teleportAdmin: AuthAccount) {
    let teleportInRef = teleportAdmin.getCapability(/private/teleportedTetherTokenTeleportIn)!
        .borrow<&TeleportedTetherToken.TeleportAdmin{TeleportedTetherToken.TeleportIn}>()
        ?? panic("Could not borrow a reference to TeleportIn")
    
    let vault <- teleportInRef.teleportIn(amount: amount, from: from.decodeHex(), hash: hash)

    let receiverRef = getAccount(target).getCapability(/public/teleportedTetherTokenReceiver)!
        .borrow<&TeleportedTetherToken.Vault{FungibleToken.Receiver}>()
        ?? panic("Could not borrow a reference to Receiver")

    receiverRef.deposit(from: <- vault)
  }
}
