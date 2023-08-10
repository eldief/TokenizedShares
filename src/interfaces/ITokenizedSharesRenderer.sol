// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/**
 * @title ITokenizedSharesRenderer.
 * @author @eldief.
 * @notice Interface defining `ITokenizedSharesRenderer` renderer contracts.
 */
interface ITokenizedSharesRenderer {
    //--------------------------------------//
    //               STRUCTS                //
    //--------------------------------------//
    struct RenderRequest {
        address tokenizedShares;
        uint256 totalReleased;
        string name;
        string symbol;
    }

    //--------------------------------------//
    //            FUNCTIONS                 //
    //--------------------------------------//
    function render(RenderRequest calldata request) external view returns (string memory);
}
