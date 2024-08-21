import "FungibleToken"
import "TeleportedTetherToken"

transaction(teleportAdmin: Address, allowedAmount: UFix64) {

  prepare(admin: auth(BorrowValue) &Account) {

    let adminRef = admin.storage.borrow<auth(TeleportedTetherToken.AdministratorEntitlement) &TeleportedTetherToken.Administrator>(from: /storage/teleportedTetherTokenAdmin)
      ?? panic("Could not borrow a reference to the admin resource")

    let allowance <- adminRef.createAllowance(allowedAmount: allowedAmount)

    let teleportUserRef = getAccount(teleportAdmin).capabilities.borrow<&{TeleportedTetherToken.TeleportUser}>(/public/teleportedTetherTokenTeleportUser)
      ?? panic("Could not borrow a reference of TeleportUser")

    teleportUserRef.depositAllowance(from: <- allowance)
  }
}