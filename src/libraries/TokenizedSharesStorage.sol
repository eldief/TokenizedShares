// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TokenizedSharesStorage.
 * @author @eldief
 * @notice Unstructured storage layout for `TokenizedShares` contracts.
 */
library TokenizedSharesStorage {
    struct Layout {
        address customRenderer;
        uint256 totalReleased;
        mapping(address => uint256) released;
        mapping(address => bool) allowedToken;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("TokenizedShares.libraries.TokenizedSharesStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
