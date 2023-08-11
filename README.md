<img src="/image/logo-full.png" width="710" height="150">

## Description
ERC1155 tradeable rights on ETH payements. Each share represent 0.1% (1 bips) of total accrued.  

Inspired by 0xSplits Liquid Split: https://docs.0xsplits.xyz/templates/liquid


## Installation

#### Install
```
forge install https://github.com/eldief/tokenized-shares
```

#### Install/update submodules
```
git submodule update --init --recursive
```

#### Add remappings
```
solady/=lib/tokenized-shares/lib/solady/src/
tokenized-shares/=lib/tokenized-shares/src/
```


## Usage

#### Import
```
import {ITokenizedShares} from "tokenized-shares/TokenizedShares.sol";
import {ITokenizedSharesController} from "tokenized-shares/TokenizedSharesController.sol";
```

#### Create
```
address newTokenizedShares = ITokenizedSharesController(controller).addTokenizedShares(
    keeperShares, recipients, shares, name, symbol
);
```

#### Deposit
```
payable(newTokenizedShares).call{value:amount}("");
```

#### Release
```
ITokenizedSharesController(controller).releaseShares(recipients);
```


## Addresses
| Chain       | Implementation                             | Controller                                 | Default Renderer                            |
|-------------|--------------------------------------------|--------------------------------------------|---------------------------------------------|
| ETH Goerli  | [0x378CeB211C4972C7d6B1A185A426FA1553c56A69](https://goerli.etherscan.io/address/0x378ceb211c4972c7d6b1a185a426fa1553c56a69) | [0x54B22db76A9Be89c3BB743744DefD8A90D304325](https://goerli.etherscan.io/address/0x54b22db76a9be89c3bb743744defd8a90d304325) |  [0x0247D43cD619E7D6dE7257066c9fF0186754E65a](https://goerli.etherscan.io/address/0x0247d43cd619e7d6de7257066c9ff0186754e65a) |
| ETH Mainnet | 0x0000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000 |  0x0000000000000000000000000000000000000000 |


## Use Cases
Some examples [here](https://github.com/eldief/tokenized-shares/tree/main/src/examples)

- NFT Royalties Recipient: Tokenized Shares can be set as the royalty recipient for Collections, Protocols or even single tokenId, allowing simple royalty dynamic distribution and enabling trading them as a royalty volume derivative. This way a Tokenized Shares owner can bet on trading volume instead of floor prices.

- Fundraising: Tokenized Shares can be sold to investors enabling real-time revenue distribution. No more forced ERC20 tokens to justify fund raising.

- DAOs: Tokenized Shares can be used as a gatekeeping/vote token with a 51% quorum, allowing decision enforcement within decentralized organizations.

- Nested ETH distribution: Tokenized Shares are mintable to other Tokenized Shares contracts unlocking infinite composability for ETH distribution.

- Combination of the above: combining use-cases, Tokenized Shares can create a custom experience for everyone.
   
- And much more... 


## Contribution
We welcome contributions to this repository.  
Please feel free to open an issue or submit a pull request if you have any enhancements or find any bugs.


## License
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.


## Safety
This is experimental software and is provided on an "as is" and "as available" basis.

We do not give any warranties and will not be liable for any loss incurred through any use of this codebase.




## Contacts
Feel free to reach out on:
- [Twitter (X)](https://twitter.com/Filllqq)
- [Telegram](https://t.me/eldief)
