import FungibleToken from 0xFUNGIBLETOKENADDRESS 
import BloctoToken from 0xBLTADDRESS
import FUSD from 0xFUSDADDRESS
import BltUsdtSwapPair from 0xBLTUSDTSWAPPAIRADDRESS
import FusdUsdtSwapPair from 0xFUSDUSDTSWAPPAIRADDRESS

transaction(maxAmountIn: UFix64, amountOut: UFix64) {
  prepare(signer: AuthAccount, proxyHolder: AuthAccount) {
    let amountUsdt = FusdUsdtSwapPair.quoteSwapToken2ForExactToken1(amount: amountOut)
    let amountIn = BltUsdtSwapPair.quoteSwapToken1ForExactToken2(amount: amountUsdt) / (1.0 - BltUsdtSwapPair.feePercentage)

    assert(amountIn < maxAmountIn, message: "Input amount too large")

    let bloctoTokenVault = signer.borrow<&BloctoToken.Vault>(from: /storage/bloctoTokenVault)
      ?? panic("Could not borrow a reference to Vault")

    let bltUsdtSwapProxy = proxyHolder.borrow<&BltUsdtSwapPair.SwapProxy>(from: /storage/bltUsdtSwapProxy)
      ?? panic("Could not borrow a reference to proxy holder")

    let fusdUsdtSwapProxy = proxyHolder.borrow<&FusdUsdtSwapPair.SwapProxy>(from: /storage/fusdUsdtSwapProxy)
      ?? panic("Could not borrow a reference to proxy holder")
    
    let token1Vault <- bloctoTokenVault.withdraw(amount: amountIn) as! @BloctoToken.Vault
    let token2Vault <- bltUsdtSwapProxy.swapToken1ForToken2(from: <-token1Vault)
    let token3Vault <- fusdUsdtSwapProxy.swapToken2ForToken1(from: <-token2Vault)

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
