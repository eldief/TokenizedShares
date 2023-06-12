// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title SharesFactoryStorage.
 * @author @eldief
 * @notice Unstructured storage layout for `SharesFactory` contract for maximum compatibility with protocol built with Diamonds pattern.
 */
library SharesFactoryStorage {
    struct Layout {
        address[] tokenizedShares;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("tokenizedshares.libraries.SharesFactoryStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
