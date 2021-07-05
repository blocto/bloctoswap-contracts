import FungibleToken from 0x9a0766d93b6608b7
import TeleportedTetherToken from 0xf4772588268a160f

transaction(amount: UFix64, target: String) {
  prepare(signer: AuthAccount) {
    let teleportOutRef = getAccount(0xf086a545ce3c552d).getCapability(/public/teleportedTetherTokenTeleportOut)!
        .borrow<&TeleportedTetherToken.TeleportAdmin{TeleportedTetherToken.TeleportOut}>()
        ?? panic("Could not borrow a reference to TeleportOut")

    let vaultRef = signer.borrow<&TeleportedTetherToken.Vault>(from: /storage/teleportedTetherTokenVault)
        ?? panic("Could not borrow a reference to the vault resource")

    let vault <- vaultRef.withdraw(amount: amount);
    
    teleportOutRef.teleportOut(from: <- vault, to: target.decodeHex())
  }
}
