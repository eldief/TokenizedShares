// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title TokenizedSharesStorage.
 * @author @eldief
 * @notice Unstructured storage layout for `TokenizedShares` contracts for maximum compatibility with protocol built with Diamonds pattern.
 */
library TokenizedSharesStorage {
    struct Layout {
        uint256 totalReleased;
        mapping(address => uint256) released;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("tokenizedshares.libraries.TokenizedSharesStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
