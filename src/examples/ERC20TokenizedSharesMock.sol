// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../ERC20TokenizedShares.sol";

/**
 * @title ERC20TokenizedSharesMock.
 * @author @eldief
 * @notice Example for ERC20 implementing Tokenized Shares.
 */
contract ERC20TokenizedSharesMock is ERC20TokenizedShares {
    function name() public pure override returns (string memory) {
        return "NAME";
    }

    function symbol() public pure override returns (string memory) {
        return "SYMBOL";
    }
}
