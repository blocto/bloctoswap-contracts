import FungibleToken from 0x9a0766d93b6608b7 
import FlowToken from 0x7e60df042a9c0868 
import TeleportedTetherToken from 0xf4772588268a160f 

// This script reads the Vault balances
pub fun main(address: Address): [UFix64] {
    // Get the accounts' public account objects
    let account = getAccount(address)

    // Get references to the account's receivers
    // by getting their public capability
    // and borrowing a reference from the capability
    let flowBalanceRef = account.getCapability(/public/flowTokenBalance)!
                        .borrow<&FlowToken.Vault{FungibleToken.Balance}>()

    let usdtBalanceRef = account.getCapability(/public/teleportedTetherTokenBalance)!
                        .borrow<&TeleportedTetherToken.Vault{FungibleToken.Balance}>()

    let flowBalance = flowBalanceRef == nil ? 0.0 : flowBalanceRef!.balance
    let usdtBalance = usdtBalanceRef == nil ? 0.0 : usdtBalanceRef!.balance
                            
    return [flowBalance, usdtBalance]
}
