// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../ERC20TokenizedShares.sol";

/**
 * @title ERC20TokenizedSharesMock.
 * @author @eldief
 * @notice Example for ERC20 implementing Tokenized Shares.
 */
contract ERC20TokenizedSharesMock is ERC20TokenizedShares {
    struct Data {
        string name;
        string symbol;
    }

    function name() public pure override returns (string memory) {
        Data memory data = abi.decode(customData(), (Data));
        return data.name;
    }

    function symbol() public pure override returns (string memory) {
        Data memory data = abi.decode(customData(), (Data));
        return data.symbol;
    }
}
