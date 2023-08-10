// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/**
 * @title TokenizedSharesControllerStorage.
 * @author @eldief
 * @notice Unstructured storage layout for `TokenizedSharesController` contract.
 */
library TokenizedSharesControllerStorage {
    struct Layout {
        address[] tokenizedShares;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("TokenizedShares.libraries.TokenizedSharesControllerStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
