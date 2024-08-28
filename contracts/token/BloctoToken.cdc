import "FungibleToken"
import "MetadataViews"
import "FungibleTokenMetadataViews"

// Token contract of Blocto Token (BLT)
access(all)
contract BloctoToken: FungibleToken{ 
    
    // An entitlement for Administrator access
    access(all) entitlement AdministratorEntitlement
    // An entitlement for Minter access
    access(all) entitlement MinterEntitlement
    // An entitlement for Burner access
    access(all) entitlement BurnerEntitlement

    // Total supply of Blocto tokens in existence
    access(all)
    var totalSupply: UFix64
    
    // Defines token vault storage path
    access(all)
    let TokenStoragePath: StoragePath
    
    // Defines token vault public balance path
    access(all)
    let TokenPublicBalancePath: PublicPath
    
    // Defines token vault public receiver path
    access(all)
    let TokenPublicReceiverPath: PublicPath
    
    // Defines token minter storage path
    access(all)
    let TokenMinterStoragePath: StoragePath
    
    // Event that is emitted when the contract is created
    access(all)
    event TokensInitialized(initialSupply: UFix64)
    
    // Event that is emitted when tokens are withdrawn from a Vault
    access(all)
    event TokensWithdrawn(amount: UFix64, from: Address?)
    
    // Event that is emitted when tokens are deposited to a Vault
    access(all)
    event TokensDeposited(amount: UFix64, to: Address?)
    
    // Event that is emitted when new tokens are minted
    access(all)
    event TokensMinted(amount: UFix64)
    
    // Event that is emitted when tokens are destroyed
    access(all)
    event TokensBurned(amount: UFix64)
    
    // Event that is emitted when a new minter resource is created
    access(all)
    event MinterCreated(allowedAmount: UFix64)
    
    // Event that is emitted when a new burner resource is created
    access(all)
    event BurnerCreated()
    

     // Gets a list of the metadata views that this contract supports
    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [
            Type<FungibleTokenMetadataViews.FTView>(),
            Type<FungibleTokenMetadataViews.FTDisplay>(),
            Type<FungibleTokenMetadataViews.FTVaultData>(),
            Type<FungibleTokenMetadataViews.TotalSupply>()
            ]
    }

    /// Get a Metadata View from BloctoToken
    ///
    /// @param view: The Type of the desired view.
    /// @return A structure representing the requested view.
    ///
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
                        url: "https://raw.githubusercontent.com/blocto/assets/main/color/flow/blt.svg"
                    ),
                    mediaType: "image/svgxml"
                )
                let medias = MetadataViews.Medias([media])
                return FungibleTokenMetadataViews.FTDisplay(
                    name: "Blocto Token",
                    symbol: "BLT",
                    description: "Blocto token (BLT) is the utility and governance token of Blocto.",
                    externalURL: MetadataViews.ExternalURL("https://blocto.io/"),
                    logos: medias,
                    socials: {
                        "x": MetadataViews.ExternalURL("https://x.com/BloctoApp")
                    }
                )
            case Type<FungibleTokenMetadataViews.FTVaultData>():
                let vaultRef = BloctoToken.account.storage.borrow<auth(FungibleToken.Withdraw) &BloctoToken.Vault>(from: /storage/BloctoTokenVault)
                    ?? panic("Could not borrow reference to the contract's Vault!")
                return FungibleTokenMetadataViews.FTVaultData(
                    storagePath: /storage/bloctoTokenVault,
                    receiverPath: /public/bloctoTokenReceiver,
                    metadataPath: /public/bloctoTokenBalance,
                    receiverLinkedType: Type<&{FungibleToken.Receiver, FungibleToken.Vault}>(),
                    metadataLinkedType: Type<&{FungibleToken.Balance, FungibleToken.Vault}>(),
                    createEmptyVaultFunction: (fun (): @{FungibleToken.Vault} {
                        return <-vaultRef.createEmptyVault()
                    })
            )
            case Type<FungibleTokenMetadataViews.TotalSupply>():
                return FungibleTokenMetadataViews.TotalSupply(totalSupply: BloctoToken.totalSupply)
        }
        return nil
    }
    // Vault
    //
    // Each user stores an instance of only the Vault in their storage
    // The functions in the Vault and governed by the pre and post conditions
    // in FungibleToken when they are called.
    // The checks happen at runtime whenever a function is called.
    //
    // Resources can only be created in the context of the contract that they
    // are defined in, so there is no way for a malicious user to create Vaults
    // out of thin air. A special Minter resource needs to be defined to mint
    // new tokens.
    //
    access(all)
    resource Vault: FungibleToken.Vault { 
        
        // holds the balance of a users tokens
        access(all)
        var balance: UFix64
        
        // initialize the balance at resource creation time
        init(balance: UFix64){ 
            self.balance = balance
        }
        
        // withdraw
        //
        // Function that takes an integer amount as an argument
        // and withdraws that amount from the Vault.
        // It creates a new temporary Vault that is used to hold
        // the money that is being transferred. It returns the newly
        // created Vault to the context that called so it can be deposited
        // elsewhere.
        //
        access(FungibleToken.Withdraw)
        fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }
        
        // deposit
        //
        // Function that takes a Vault object as an argument and adds
        // its balance to the balance of the owners Vault.
        // It is allowed to destroy the sent Vault because the Vault
        // was a temporary holder of the tokens. The Vault's balance has
        // been consumed and therefore can be destroyed.
        access(all)
        fun deposit(from: @{FungibleToken.Vault}): Void{ 
            let vault <- from as! @BloctoToken.Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault
        }
        
        access(all)
        fun createEmptyVault(): @{FungibleToken.Vault}{ 
            return <-create Vault(balance: 0.0)
        }
        
        access(all)
        view fun isAvailableToWithdraw(amount: UFix64): Bool{ 
            return self.balance >= amount
        }


        // Called when a fungible token is burned via the `Burner.burn()` method
        access(contract) fun burnCallback() {
            if self.balance > 0.0 {
                BloctoToken.totalSupply = BloctoToken.totalSupply - self.balance
            }
            self.balance = 0.0
        }

        // getSupportedVaultTypes optionally returns a list of vault types that this receiver accepts
        access(all) view fun getSupportedVaultTypes(): {Type: Bool} {
            return {self.getType(): true}
        }

        access(all) view fun isSupportedVaultType(type: Type): Bool {
            if (type == self.getType()) { return true } else { return false }
        }


         // Get all the Metadata Views implemented by FlowToken
        //
        // @return An array of Types defining the implemented views. This value will be used by
        //         developers to know which parameter to pass to the resolveView() method.
        //
        access(all) view fun getViews(): [Type]{
            return BloctoToken.getContractViews(resourceType: nil)
        }

        // Get a Metadata View from FlowToken
        //
        // @param view: The Type of the desired view.
        // @return A structure representing the requested view.
        //
        access(all) fun resolveView(_ view: Type): AnyStruct? {
            return BloctoToken.resolveContractView(resourceType: nil, viewType: view)
        }
    }
    
    // createEmptyVault
    //
    // Function that creates a new Vault with a balance of zero
    // and returns it to the calling context. A user must call this function
    // and store the returned Vault in their storage in order to allow their
    // account to be able to receive deposits of this token type.
    //
    access(all)
    fun createEmptyVault(vaultType: Type): @BloctoToken.Vault{ 
        return <-create Vault(balance: 0.0)
    }
    
    access(all)
    resource Administrator{ 
        // createNewMinter
        //
        // Function that creates and returns a new minter resource
        //
        access(AdministratorEntitlement)
        fun createNewMinter(allowedAmount: UFix64): @Minter{ 
            emit MinterCreated(allowedAmount: allowedAmount)
            return <-create Minter(allowedAmount: allowedAmount)
        }
        
        // createNewBurner
        //
        // Function that creates and returns a new burner resource
        //
        access(AdministratorEntitlement)
        fun createNewBurner(): @Burner{ 
            emit BurnerCreated()
            return <-create Burner()
        }
    }
    
    // Minter
    //
    // Resource object that token admin accounts can hold to mint new tokens.
    //
    access(all)
    resource Minter{ 
        
        // the amount of tokens that the minter is allowed to mint
        access(all)
        var allowedAmount: UFix64
        
        // mintTokens
        //
        // Function that mints new tokens, adds them to the total supply,
        // and returns them to the calling context.
        //
        access(MinterEntitlement)
        fun mintTokens(amount: UFix64): @BloctoToken.Vault{ 
            pre{ 
                amount > 0.0:
                    "Amount minted must be greater than zero"
                amount <= self.allowedAmount:
                    "Amount minted must be less than the allowed amount"
            }
            BloctoToken.totalSupply = BloctoToken.totalSupply + amount
            self.allowedAmount = self.allowedAmount - amount
            emit TokensMinted(amount: amount)
            return <-create Vault(balance: amount)
        }
        
        init(allowedAmount: UFix64){ 
            self.allowedAmount = allowedAmount
        }
    }
    
    // Burner
    //
    // Resource object that token admin accounts can hold to burn tokens.
    //
    access(all)
    resource Burner{ 
        
        // burnTokens
        //
        // Function that destroys a Vault instance, effectively burning the tokens.
        //
        // Note: the burned tokens are automatically subtracted from the
        // total supply in the Vault destructor.
        //
        access(BurnerEntitlement)
        fun burnTokens(from: @{FungibleToken.Vault}){ 
            let vault <- from as! @BloctoToken.Vault
            let amount = vault.balance
            BloctoToken.totalSupply = BloctoToken.totalSupply - amount
            destroy vault
            emit TokensBurned(amount: amount)
        }
    }
    
    init() { 
        // Total supply of BLT is 500M
        // 70% is created at genesis but locked up
        // 30% will minted from staking and mining
        self.totalSupply = 350_000_000.0

        self.TokenStoragePath = /storage/bloctoTokenVault
        self.TokenPublicReceiverPath = /public/bloctoTokenReceiver
        self.TokenPublicBalancePath = /public/bloctoTokenBalance
        self.TokenMinterStoragePath = /storage/bloctoTokenMinter
        
        // Create the Vault with the total supply of tokens and save it in storage
        let vault <- create Vault(balance: self.totalSupply)
        self.account.storage.save(<-vault, to: self.TokenStoragePath)
        
        // Create a public capability to the stored Vault that only exposes
        // the `deposit` method through the `Receiver` interface
        var capability_1 = self.account.capabilities.storage.issue<&BloctoToken.Vault>(self.TokenStoragePath)
        self.account.capabilities.publish(capability_1, at: self.TokenPublicReceiverPath)
        
        // Create a public capability to the stored Vault that only exposes
        // the `balance` field through the `Balance` interface
        var capability_2 = self.account.capabilities.storage.issue<&BloctoToken.Vault>(self.TokenStoragePath)
        self.account.capabilities.publish(capability_2, at: self.TokenPublicBalancePath)
        let admin <- create Administrator()
        self.account.storage.save(<-admin, to: /storage/bloctoTokenAdmin)
        
        // Emit an event that shows that the contract was initialized
        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}