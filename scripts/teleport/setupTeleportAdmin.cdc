import FungibleToken from 0xFUNGIBLETOKENADDRESS
import TeleportedTetherToken from 0xTOKENADDRESS

transaction {
  prepare(admin: AuthAccount, teleportAdmin: AuthAccount) {

    let adminRef = admin.borrow<&TeleportedTetherToken.Administrator>(from: /storage/teleportedTetherTokenAdmin)
        ?? panic("Could not borrow a reference to the admin resource")

    let teleportAdminRes <- adminRef.createNewTeleportAdmin()

    teleportAdmin.save(<- teleportAdminRes, to: /storage/teleportedTetherTokenTeleportAdmin)

    teleportAdmin.link<&TeleportedTetherToken.TeleportAdmin{TeleportedTetherToken.TeleportIn}>(
      /private/teleportedTetherTokenTeleportIn,
      target: /storage/teleportedTetherTokenTeleportAdmin
    )

    teleportAdmin.link<&TeleportedTetherToken.TeleportAdmin{TeleportedTetherToken.TeleportOut}>(
      /public/teleportedTetherTokenTeleportOut,
      target: /storage/teleportedTetherTokenTeleportAdmin
    )

    teleportAdmin.link<&TeleportedTetherToken.TeleportAdmin{TeleportedTetherToken.TeleportConfig}>(
      /private/teleportedTetherTokenTeleportConfig,
      target: /storage/teleportedTetherTokenTeleportAdmin
    )
  }
}
