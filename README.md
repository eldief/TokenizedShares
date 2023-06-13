# TokenizedShares
Clone and mint Tokenized Shares to be set as ETH payment recipients. Each share represent 0.1% (1 bips) of total accrued.



## Compatibility
All contract storages are built with UnstructuredStorage for Proxy/Diamond compatibility.



## Composability
TokenizedShares as tradeable royalties rights:  

Unlock maximum composability for your protocol setting your custom `ITokenizedShares` as royalties recipient.  
Royalites can be accrued on proxied `ITokenizedShares` and later proportionally released to shares `owners` by anyone.  
A `keeperShares` fee can be set during proxy creation to involve keepers in share releasing when profitable.

Granularity can be custom defined on protocol implementation, you can decided if `ITokenizedShares` is for accruing royalties for whole collection or for a single token. Both examples can be found [here](https://github.com/eldief/TokenizedShares/tree/main/src/examples). 

Being ERC1155 or ERC20 tokens, TokenizedShares can be traded freely on the open market allowing for more building blocks to be developed on.  
Buying a TokenizedShare of a collection would allow it's owner to bet on a collection volume, removing floor price from the equation.



## Contracts

### SharesFactory 
  Tokenized Shares Factory [contract](https://github.com/eldief/TokenizedShares/blob/main/src/SharesFactory.sol). Contains two functions: 

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

  - `customData`: Immutable encoded bytes injected while cloning `ITokenizedShares`.
    - Optional. 
    - Default: empty.
    - [Example](https://github.com/eldief/TokenizedShares/blob/main/src/mocks/ERC1155TokenSharesMock.sol)

  `releaseShares`: Release ETH accrued by `ITokenizedShares`.
  - `owners`: Address array of shares owners to release ETH to.
    - Required.
    - Cannot be empty.

  - `tokenizedShares`: Address array of `ITokenizedShares` proxies.
    - Optional.
    - Default: All `ITokenizedShares` created by `SharesFactory`.


### ITokenizedShares 
  [Interface](https://github.com/eldief/TokenizedShares/blob/main/src/interfaces/ITokenizedShares.sol) that defines TokenizedShares implementation, contains 2 main functions:  
  - `factoryMintShares`: Mint new shares. 
 
  - `releaseShares`: Release ETH to `owners`, proportionally on how many `TokenShares` they own.  


### ERC20TokenizedShares
  Abstract [contract](https://github.com/eldief/TokenizedShares/blob/main/src/ERC20TokenizedShares.sol) defining a default ERC20 `ITokenizedShares` implementation.


### ERC1155TokenizedShares
  Abstract [contract](https://github.com/eldief/TokenizedShares/blob/main/src/ERC1155TokenizedShares.sol) defining a default ERC1155 `ITokenizedShares` implementation.



## Contributions
We welcome contributions to this repository. Please feel free to open an issue or submit a pull request if you have any enhancements or find any bugs.



## Disclaimer
These smart contracts are for educational purposes only and not intended for production use. Use at your own risk. Always make sure to test them thoroughly before deploying them into a production environment.
