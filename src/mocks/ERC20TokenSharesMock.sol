// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../ERC20TokenizedShares.sol";

contract ERC20TokenSharesMock is ERC20TokenizedShares {
    string internal constant _name = "";
    string internal constant _symbol = "";

    function name() public pure override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
        return _symbol;
    }
}
