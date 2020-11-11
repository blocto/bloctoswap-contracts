// This transaction is a template for a transaction
// to add a Vault resource to their account
// so that they can use the teleportedTetherToken (USDT)

import FungibleToken from 0x01
import TeleportedTetherToken from 0x02

transaction {
  prepare(signer: AuthAccount) {
    let teleportOutRef = getAccount(0x03).getCapability(/public/teleportedTetherTokenTeleportOut)!
        .borrow<&TeleportedTetherToken.TeleportAdmin{TeleportedTetherToken.TeleportOut}>()
        ?? panic("Could not borrow a reference to TeleportOut")

    let vaultRef = signer.borrow<&TeleportedTetherToken.Vault>(from: /storage/teleportedTetherTokenVault)
        ?? panic("Could not borrow a reference to the vault resource")

    let vault <- vaultRef.withdraw(amount: 9.9);
    
    teleportOutRef.teleportOut(from: <- vault, to: "19818f44Faf5A217F619AFF0FD487CB2a55cCa65ff".decodeHex())
  }
}
