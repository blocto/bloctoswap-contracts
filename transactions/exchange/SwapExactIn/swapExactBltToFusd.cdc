import FUSD from 0xFUSDADDRESS
import BloctoToken from 0xBLTADDRESS
import BltUsdtSwapPair from 0xBLTUSDTSWAPPAIRADDRESS
import FusdUsdtSwapPair from 0xFUSDUSDTSWAPPAIRADDRESS

transaction(amountIn: UFix64, minAmountOut: UFix64) {
  prepare(signer: AuthAccount, proxyHolder: AuthAccount) {
    let bloctoTokenVault = signer.borrow<&BloctoToken.Vault>(from: /storage/bloctoTokenVault)
      ?? panic("Could not borrow a reference to Vault")

    let bltUsdtSwapProxy = proxyHolder.borrow<&BltUsdtSwapPair.SwapProxy>(from: /storage/bltUsdtSwapProxy)
      ?? panic("Could not borrow a reference to proxy holder")

    let token3Vault <- bloctoTokenVault.withdraw(amount: amountIn) as! @BloctoToken.Vault
    let token2Vault <- bltUsdtSwapProxy.swapToken1ForToken2(from: <-token3Vault)

    let quote = FusdUsdtSwapPair.quoteSwapExactToken2ForToken1(amount: amountIn)

    let fusdUsdtSwapProxy = proxyHolder.borrow<&FusdUsdtSwapPair.SwapProxy>(from: /storage/fusdUsdtSwapProxy)
      ?? panic("Could not borrow a reference to proxy holder")

    let token1Vault <- fusdUsdtSwapProxy.swapToken2ForToken1(from: <-token2Vault)

    assert(token1Vault.balance > minAmountOut, message: "Output amount too small")

    let fusdVault = signer.borrow<&FUSD.Vault>(from: /storage/fusdVault)
      ?? panic("Could not borrow a reference to Vault")

    fusdVault.deposit(from: <- token1Vault)
  }
}
