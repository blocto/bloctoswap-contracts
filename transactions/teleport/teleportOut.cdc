import "FungibleToken"
import "TeleportedTetherToken"

transaction(teleportAdmin: Address, amount: UFix64, target: String) {

  prepare(signer: auth(BorrowValue) &Account) {

    let teleportUserRef = getAccount(teleportAdmin).capabilities.borrow<&{TeleportedTetherToken.TeleportUser}>(/public/teleportedTetherTokenTeleportUser)
      ?? panic("Could not borrow a reference to TeleportUser")

    let vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &TeleportedTetherToken.Vault>(from: TeleportedTetherToken.TokenStoragePath)
      ?? panic("Could not borrow a reference to the vault resource")

    let vault <- vaultRef.withdraw(amount: amount)

    teleportUserRef.teleportOut(from: <- vault, to: target.decodeHex())
  }
}