import FungibleToken from 0xFUNGIBLETOKENADDRESS
import TeleportedTetherToken from 0xTOKENADDRESS

transaction {
  let receiverRef: &TeleportedTetherToken.Vault{FungibleToken.Receiver}
  let admin: AuthAccount
  let teleportAdmin: AuthAccount

  prepare(admin: AuthAccount, teleportAdmin: AuthAccount) {

    // Make sure teleport admin account has Tel
    self.receiverRef = teleportAdmin.getCapability(/public/teleportedTetherTokenReceiver)!
                      .borrow<&TeleportedTetherToken.Vault{FungibleToken.Receiver}>()
                      ?? panic("Could not borrow a reference to the token receiver")

    self.admin = admin
    self.teleportAdmin = teleportAdmin
  }

  execute {
    let adminRef = self.admin.borrow<&TeleportedTetherToken.Administrator>(from: /storage/teleportedTetherTokenAdmin)
        ?? panic("Could not borrow a reference to the admin resource")

    let teleportAdminRes <- adminRef.createNewTeleportAdmin(feeCollector: self.receiverRef)

    self.teleportAdmin.save(<- teleportAdminRes, to: /storage/teleportedTetherTokenTeleportAdmin)

    self.teleportAdmin.link<&TeleportedTetherToken.TeleportAdmin{TeleportedTetherToken.TeleportIn}>(
      /private/teleportedTetherTokenTeleportIn,
      target: /storage/teleportedTetherTokenTeleportAdmin
    )

    self.teleportAdmin.link<&TeleportedTetherToken.TeleportAdmin{TeleportedTetherToken.TeleportOut}>(
      /public/teleportedTetherTokenTeleportOut,
      target: /storage/teleportedTetherTokenTeleportAdmin
    )

    self.teleportAdmin.link<&TeleportedTetherToken.TeleportAdmin{TeleportedTetherToken.TeleportConfig}>(
      /private/teleportedTetherTokenTeleportConfig,
      target: /storage/teleportedTetherTokenTeleportAdmin
    )
  }
}
