// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../ERC1155TokenizedShares.sol";

contract ERC1155TokenSharesMock is ERC1155TokenizedShares {
    string internal constant _uri = "";

    function uri(uint256) public pure override returns (string memory) {
        return _uri;
    }
}
