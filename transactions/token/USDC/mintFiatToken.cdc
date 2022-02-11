import FungibleToken from "../../../contracts/token/FungibleToken.cdc"
import FiatToken from "../../../contracts/token/FiatToken.cdc"

transaction(amount: UFix64, to: Address) {

    let tokenMinter: &FiatToken.Minter
    let tokenReceiver: &{FungibleToken.Receiver}

    prepare(minterAccount: AuthAccount) {
        self.tokenMinter = minterAccount
            .borrow<&FiatToken.Minter>(from: /storage/usdcMinter)
            ?? panic("No minter available")

        self.tokenReceiver = getAccount(to)
            .getCapability(FiatToken.VaultReceiverPubPath)
            .borrow<&{FungibleToken.Receiver}>()
            ?? panic("Unable to borrow receiver reference")
    }

    execute {
        let mintedVault <- self.tokenMinter.mintTokens(amount: amount)

        self.tokenReceiver.deposit(from: <- (mintedVault as! @FungibleToken.Vault))
    }
}
