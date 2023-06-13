// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../ERC1155TokenizedShares.sol";

/**
 * @title ERC1155TokenizedSharesMock.
 * @author @eldief
 * @notice Example for ERC1155 implementing Tokenized Shares.
 */

contract ERC1155TokenizedSharesMock is ERC1155TokenizedShares {
    struct Data {
        string name;
        string symbol;
        string uri;
    }

    function name() public pure returns (string memory) {
        Data memory data = abi.decode(customData(), (Data));
        return data.name;
    }

    function symbol() public pure returns (string memory) {
        Data memory data = abi.decode(customData(), (Data));
        return data.symbol;
    }

    function uri(uint256) public pure override returns (string memory) {
        Data memory data = abi.decode(customData(), (Data));
        return data.uri;
    }
}
