import FungibleToken from 0xFUNGIBLETOKENADDRESS 
import FlowToken from 0xFLOWTOKENADDRESS
import FUSD from 0xFUSDADDRESS
import FlowSwapPair from 0xFLOWSWAPPAIRADDRESS
import FusdUsdtSwapPair from 0xFUSDUSDTSWAPPAIRADDRESS

transaction(amountIn: UFix64, minAmountOut: UFix64) {
  prepare(signer: AuthAccount, proxyHolder: AuthAccount) {
    let flowVault = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
      ?? panic("Could not borrow a reference to Vault")

    let flowUsdtSwapProxy = proxyHolder.borrow<&FlowSwapPair.SwapProxy>(from: /storage/flowUsdtSwapProxy)
      ?? panic("Could not borrow a reference to proxy holder")

    let fusdUsdtSwapProxy = proxyHolder.borrow<&FusdUsdtSwapPair.SwapProxy>(from: /storage/fusdUsdtSwapProxy)
      ?? panic("Could not borrow a reference to proxy holder")
    
    let token1Vault <- flowVault.withdraw(amount: amountIn) as! @FlowToken.Vault
    let token2Vault <- flowUsdtSwapProxy.swapToken1ForToken2(from: <-token1Vault)
    let token3Vault <- fusdUsdtSwapProxy.swapToken2ForToken1(from: <-token2Vault)

    assert(token3Vault.balance > minAmountOut, message: "Output amount too small")

    if signer.borrow<&FUSD.Vault>(from: /storage/fusdVault) == nil {
      // Create a new FUSD Vault and put it in storage
      signer.save(<-FUSD.createEmptyVault(), to: /storage/fusdVault)

      // Create a public capability to the Vault that only exposes
      // the deposit function through the Receiver interface
      signer.link<&FUSD.Vault{FungibleToken.Receiver}>(
        /public/fusdReceiver,
        target: /storage/fusdVault
      )

      // Create a public capability to the Vault that only exposes
      // the balance field through the Balance interface
      signer.link<&FUSD.Vault{FungibleToken.Balance}>(
        /public/fusdBalance,
        target: /storage/fusdVault
      )
    }

    let fusdVault = signer.borrow<&FUSD.Vault>(from: /storage/fusdVault)
        ?? panic("Could not borrow a reference to Vault")

    fusdVault.deposit(from: <- token3Vault)
  }
}
