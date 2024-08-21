import "FungibleToken"
import "TeleportedTetherToken"

transaction(allowedAmount: UFix64) {

  prepare(admin: auth(BorrowValue) &Account, teleportAdmin: auth(SaveValue, LoadValue, Capabilities) &Account) {

    let adminRef = admin.storage.borrow<auth(TeleportedTetherToken.AdministratorEntitlement) &TeleportedTetherToken.Administrator>(from: /storage/teleportedTetherTokenAdmin)
      ?? panic("Could not borrow a reference to the admin resource")

    let teleportAdminRes <- adminRef.createNewTeleportAdmin(allowedAmount: allowedAmount)

    destroy teleportAdmin.storage.load<@TeleportedTetherToken.TeleportAdmin>(from: /storage/teleportedTetherTokenTeleportAdmin)
    let cap = teleportAdmin.capabilities.unpublish(/public/teleportedTetherTokenTeleportUser)
    teleportAdmin.storage.save(<- teleportAdminRes, to: /storage/teleportedTetherTokenTeleportAdmin)

    let teleportUserCap = teleportAdmin.capabilities.storage.issue<&{TeleportedTetherToken.TeleportUser}>(/storage/teleportedTetherTokenTeleportAdmin)
    teleportAdmin.capabilities.publish(teleportUserCap, at: /public/teleportedTetherTokenTeleportUser)
  }
}