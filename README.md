# Tokenized Shares
  <img src="/image/TokenizedShares.png" width="600" height="600">

  Clone and mint Tokenized Shares to be set as ETH payment recipients. Each share represent 0.1% (1 bips) of total accrued.  
  Inspired by 0xSplits Liquid Split: https://docs.0xsplits.xyz/templates/liquid


# Addresses
  Goerli:
  - SharesFactory: [0xEdfe971b70Ebe665A60099e4d4fbd25140c29800](https://goerli.etherscan.io/address/0xEdfe971b70Ebe665A60099e4d4fbd25140c29800)
  - DefaultTokenizedShares: [0xb1296aa3599307cced1494c5fbacbb9d5e3241d5](https://goerli.etherscan.io/address/0xb1296aa3599307cced1494c5fbacbb9d5e3241d5)
  - OpenSea Testnet: https://testnets.opensea.io/assets/goerli/0xc91efbc6e7239410afd5c5dc767adde02ff8af1b/0

  Mainnet:
  - SharesFactory: TBD
  - DefaultTokenizedShares: TBD



# Compatibility
  All contract storages are built with UnstructuredStorage for Proxy/Diamond compatibility.



# Composability
  TokenizedShares as tradeable royalties rights:  

  Unlock maximum composability for your protocol setting your custom `ITokenizedShares` as royalties recipient.  
  Royalites can be accrued on proxied `ITokenizedShares` and later proportionally released to shares `owners` by anyone.  

  A `keeperShares` fee can be set during proxy creation to involve keepers in share releasing when profitable.

  Granularity can be custom defined on protocol implementation, you can decide if `ITokenizedShares` is for accruing royalties for a whole collection, multiple collections or for a single token.  
  Examples can be found [here](https://github.com/eldief/TokenizedShares/tree/main/src/examples). 

  Being ERC1155 or ERC20 tokens, TokenizedShares can be traded freely on the open market allowing for more building blocks to be developed on.  

  Buying a TokenizedShare of a collection would allow it's owner to bet on a collection volume, removing floor price from the equation.



# Contracts

## SharesFactory 
  Tokenized Shares Factory [contract](https://github.com/eldief/TokenizedShares/blob/main/src/SharesFactory.sol).  
  
  Functions: 

  `addTokenizedShares`: Create a new proxy to `ITokenizedShares` and mint shares to recipients.
  - `recipients`: Address array to mint Shares to.
    - Required.
    - Cannot be empty.

  - `shares`: Uint256 array of shares amount to be minted for each `recipients`.
    - Required.
    - Must have the same length of `recipients`.
    - Sum of `shares` + `keeperShares` must be exactly 10_000.

  - `implementation`: Custom `ITokenizedShares` implementation to be proxied.
    - Optional. 
    - Default: `defaultImplementation`.

  - `keeperShares`: Amount reserved to be payed to keepers (`tx.origin`) while executing `releaseShares`. 
    - Optional. 
    - Default: 0%. 
    - Max: 1_000 (10%).
    - Sum of `shares` + `keeperShares` must be exactly 10_000.

  `releaseShares`: Release ETH accrued by `ITokenizedShares`.
  - `owners`: Address array of shares owners to release ETH to.
    - Required.
    - Cannot be empty.

  - `tokenizedShares`: Address array of `ITokenizedShares` proxies.
    - Optional.
    - Default: All `ITokenizedShares` created by `SharesFactory`.

  `releasable`: Returns ETH accrued by `ITokenizedShares` for `owner`.
  - `owner`: Address of shares owner to release ETH to.
    - Required.

  - `tokenizedShares`: Address array of `ITokenizedShares` proxies.
    - Optional.
    - Default: All `ITokenizedShares` created by `SharesFactory`.


## ITokenizedShares 
  [Interface](https://github.com/eldief/TokenizedShares/blob/main/src/interfaces/ITokenizedShares.sol) that defines TokenizedShares implementation.  
  
  Functions:
  
  `factoryMintShares`: Mint new shares. 
 
  `releaseShares`: Release ETH to `owners`, proportionally on how many `TokenShares` they own.  
  
  `releasable`: Returns ETH accrued by `ITokenizedShares` for `owner`.  
  
  `totalReleased`: Returns total amount of ETH released by `ITokenizedShares` contract for owners and keepers.  


## DefaultTokenizedShares
  Default ERC1155 [contract](https://github.com/eldief/TokenizedShares/blob/main/src/DefaultTokenizedShares.sol) `ITokenizedShares` implementation. This contract will be proxied if no `implementation` is set during `addTokenizedShares`.  
  
  Comes with a pretty on-chain dynamic svg displaying proxy address and total ETH released by it! 


## ERC20TokenizedShares
  Abstract [contract](https://github.com/eldief/TokenizedShares/blob/main/src/ERC20TokenizedShares.sol) defining a default ERC20 `ITokenizedShares` implementation.


## ERC1155TokenizedShares
  Abstract [contract](https://github.com/eldief/TokenizedShares/blob/main/src/ERC1155TokenizedShares.sol) defining a default ERC1155 `ITokenizedShares` implementation.



# Contributions
We welcome contributions to this repository. Please feel free to open an issue or submit a pull request if you have any enhancements or find any bugs.



# Disclaimer
These smart contracts are for educational purposes only and not intended for production use. Use at your own risk. Always make sure to test them thoroughly before deploying them into a production environment.
