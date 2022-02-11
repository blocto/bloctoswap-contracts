import FiatToken from "../../../contracts/token/FiatToken.cdc"

transaction {

    prepare(adminAccount: AuthAccount) {

        let tokenAdmin = adminAccount.borrow<&FiatToken.Administrator>(from: FiatToken.AdminStoragePath)
            ?? panic("Could not borrow a reference to the admin resource")

        // Create a new minter resource and a private link to a capability for it in the admin's storage.
        let minter <- tokenAdmin.createNewMinter()
        adminAccount.save(<- minter, to: /storage/usdcMinter)
    }
}
