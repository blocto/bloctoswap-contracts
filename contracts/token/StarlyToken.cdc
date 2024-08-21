import "FungibleToken"
import "MetadataViews"
import "FungibleTokenMetadataViews"

access(all) contract StarlyToken: FungibleToken {
    access(all) var totalSupply: UFix64

    access(all) let TokenStoragePath: StoragePath
    access(all) let TokenPublicBalancePath: PublicPath
    access(all) let TokenPublicReceiverPath: PublicPath

    access(all) event TokensMinted(amount: UFix64, type: String)

    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [
            Type<FungibleTokenMetadataViews.FTView>(),
            Type<FungibleTokenMetadataViews.FTDisplay>(),
            Type<FungibleTokenMetadataViews.FTVaultData>(),
            Type<FungibleTokenMetadataViews.TotalSupply>()
        ]
    }

    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
            case Type<FungibleTokenMetadataViews.FTView>():
                return FungibleTokenMetadataViews.FTView(
                    ftDisplay: self.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTDisplay>()) as! FungibleTokenMetadataViews.FTDisplay?,
                    ftVaultData: self.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTVaultData>()) as! FungibleTokenMetadataViews.FTVaultData?
                )
            case Type<FungibleTokenMetadataViews.FTDisplay>():
                let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                        url: "https://storage.googleapis.com/starly-prod.appspot.com/assets/starly-icon-black.png"
                    ),
                    mediaType: "image/png"
                )
                let medias = MetadataViews.Medias([media])
                return FungibleTokenMetadataViews.FTDisplay(
                    name: "Starly Token",
                    symbol: "STARLY",
                    description: "STARLY is a utility token which serves as a medium to offer creators, collectors and the surrounding communities the ultimate experience on Starly ecosystem.",
                    externalURL: MetadataViews.ExternalURL("https://starly.io/"),
                    logos: medias,
                    socials: {
                        "twitter": MetadataViews.ExternalURL("https://x.com/StarlyNFT"),
                        "telegram": MetadataViews.ExternalURL("https://t.me/starlynft")
                    }
                )
            case Type<FungibleTokenMetadataViews.FTVaultData>():
                return FungibleTokenMetadataViews.FTVaultData(
                    storagePath: self.TokenStoragePath,
                    receiverPath: self.TokenPublicReceiverPath,
                    metadataPath: self.TokenPublicBalancePath,
                    receiverLinkedType: Type<&StarlyToken.Vault>(),
                    metadataLinkedType: Type<&StarlyToken.Vault>(),
                    createEmptyVaultFunction: (fun(): @{FungibleToken.Vault} {
                        return <-StarlyToken.createEmptyVault(vaultType: Type<@StarlyToken.Vault>())
                    })
                )
            case Type<FungibleTokenMetadataViews.TotalSupply>():
                return FungibleTokenMetadataViews.TotalSupply(
                    totalSupply: StarlyToken.totalSupply
                )
        }
        return nil
    }

    access(all) resource Vault: FungibleToken.Vault {

        /// The total balance of this vault
        access(all) var balance: UFix64

        // initialize the balance at resource creation time
        init(balance: UFix64) {
            self.balance = balance
        }

        /// Called when a fungible token is burned via the `Burner.burn()` method
        access(contract) fun burnCallback() {
            if self.balance > 0.0 {
                StarlyToken.totalSupply = StarlyToken.totalSupply - self.balance
            }
            self.balance = 0.0
        }

        access(all) view fun getViews(): [Type] {
            return StarlyToken.getContractViews(resourceType: nil)
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            return StarlyToken.resolveContractView(resourceType: nil, viewType: view)
        }

        /// getSupportedVaultTypes optionally returns a list of vault types that this receiver accepts
        access(all) view fun getSupportedVaultTypes(): {Type: Bool} {
            let supportedTypes: {Type: Bool} = {}
            supportedTypes[self.getType()] = true
            return supportedTypes
        }

        access(all) view fun isSupportedVaultType(type: Type): Bool {
            return self.getSupportedVaultTypes()[type] ?? false
        }

        /// Asks if the amount can be withdrawn from this vault
        access(all) view fun isAvailableToWithdraw(amount: UFix64): Bool {
            return amount <= self.balance
        }

        /// withdraw
        ///
        /// Function that takes an amount as an argument
        /// and withdraws that amount from the Vault.
        ///
        /// It creates a new temporary Vault that is used to hold
        /// the tokens that are being transferred. It returns the newly
        /// created Vault to the context that called so it can be deposited
        /// elsewhere.
        ///
        access(FungibleToken.Withdraw) fun withdraw(amount: UFix64): @StarlyToken.Vault {
            self.balance = self.balance - amount
            return <-create Vault(balance: amount)
        }

        /// deposit
        ///
        /// Function that takes a Vault object as an argument and adds
        /// its balance to the balance of the owners Vault.
        ///
        /// It is allowed to destroy the sent Vault because the Vault
        /// was a temporary holder of the tokens. The Vault's balance has
        /// been consumed and therefore can be destroyed.
        ///
        access(all) fun deposit(from: @{FungibleToken.Vault}) {
            let vault <- from as! @StarlyToken.Vault
            self.balance = self.balance + vault.balance
            vault.balance = 0.0
            destroy vault
        }

        /// createEmptyVault
        ///
        /// Function that creates a new Vault with a balance of zero
        /// and returns it to the calling context. A user must call this function
        /// and store the returned Vault in their storage in order to allow their
        /// account to be able to receive deposits of this token type.
        ///
        access(all) fun createEmptyVault(): @StarlyToken.Vault {
            return <-create Vault(balance: 0.0)
        }
    }

    /// createEmptyVault
    ///
    /// Function that creates a new Vault with a balance of zero
    /// and returns it to the calling context. A user must call this function
    /// and store the returned Vault in their storage in order to allow their
    /// account to be able to receive deposits of this token type.
    ///
    access(all) fun createEmptyVault(vaultType: Type): @StarlyToken.Vault {
        return <- create Vault(balance: 0.0)
    }

    init() {
        self.totalSupply = 100_000_000.0

        self.TokenStoragePath = /storage/starlyTokenVault
        self.TokenPublicBalancePath = /public/starlyTokenVault
        self.TokenPublicReceiverPath = /public/starlyTokenReceiver

        let vault <- create Vault(balance: self.totalSupply)
        emit TokensMinted(amount: vault.balance, type: vault.getType().identifier)

        let starlyTokenCap = self.account.capabilities.storage.issue<&StarlyToken.Vault>(self.TokenStoragePath)
        self.account.capabilities.publish(starlyTokenCap, at: self.TokenPublicBalancePath)
        let receiverCap = self.account.capabilities.storage.issue<&StarlyToken.Vault>(self.TokenStoragePath)
        self.account.capabilities.publish(receiverCap, at: self.TokenPublicReceiverPath)
        self.account.storage.save(<-vault, to: /storage/starlyTokenVault)
    }
}
