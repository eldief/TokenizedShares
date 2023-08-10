// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITokenizedSharesRenderer} from "./interfaces/ITokenizedSharesRenderer.sol";
import {Base64} from "solady/utils/Base64.sol";
import {SSTORE2} from "solady/utils/SSTORE2.sol";
import {LibString} from "solady/utils/LibString.sol";
import {DynamicBufferLib} from "solady/utils/DynamicBufferLib.sol";

/**
 * @title  .
 * @author @eldief
 * @notice Default implementation of TokenizedShares.
 */
contract TokenizedSharesRenderer is ITokenizedSharesRenderer {
    using LibString for *;
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;

    //--------------------------------------//
    //    STORAGE - CONSTANTS/IMMUTABLES    //
    //--------------------------------------//

    /**
     * @dev Uri svg SSTORE2 chunk addresses.
     */
    address internal immutable _chunk0;
    address internal immutable _chunk1;
    address internal immutable _chunk2;
    address internal immutable _chunk3;

    constructor(address chunk0_, address chunk1_, address chunk2_, address chunk3_) {
        _chunk0 = chunk0_;
        _chunk1 = chunk1_;
        _chunk2 = chunk2_;
        _chunk3 = chunk3_;
    }

    //--------------------------------------//
    //              RENDERERING             //
    //--------------------------------------//
    function render(RenderRequest calldata request) public view override returns (string memory) {
        bytes memory strAddress = bytes(request.tokenizedShares.toHexStringChecksummed());
        bytes memory strTotalReleased = buildStrTotalReleased(request.totalReleased);

        DynamicBufferLib.DynamicBuffer memory jsonBuffer;
        jsonBuffer.append('{"name":"', bytes(request.name), '",');
        jsonBuffer.append('"description":"Tokenized Shares Id:', strAddress, '",');
        jsonBuffer.append('"attributes":', buildAttributes(strTotalReleased, strAddress), ",");
        jsonBuffer.append('"image":"data:image/svg+xml;base64,', buildImage(strTotalReleased, strAddress), '"}');

        return string(abi.encodePacked("data:application/json;base64,", bytes(Base64.encode(jsonBuffer.data))));
    }

    function buildStrTotalReleased(uint256 totalReleased) internal pure returns (bytes memory) {
        uint256 integer = totalReleased / 1e18;
        uint256 decimal = totalReleased - integer * 1e18;

        bytes memory strInteger = bytes(LibString.toString(integer));
        bytes memory strDecimal = bytes(LibString.toString(decimal));

        return abi.encodePacked(strInteger, ".", strDecimal);
    }

    function buildImage(bytes memory strTotalReleased, bytes memory strAddress) internal view returns (bytes memory) {
        DynamicBufferLib.DynamicBuffer memory buffer;
        buffer.append(SSTORE2.read(_chunk0));
        buffer.append(SSTORE2.read(_chunk1), strAddress);
        buffer.append(SSTORE2.read(_chunk2), strTotalReleased);
        buffer.append(SSTORE2.read(_chunk3));
        return bytes(Base64.encode(buffer.data));
    }

    function buildAttributes(bytes memory strTotalReleased, bytes memory strAddress)
        internal
        pure
        returns (bytes memory)
    {
        DynamicBufferLib.DynamicBuffer memory buffer;
        buffer.append('[{"trait_type":"Id","value":"', strAddress, '"},');
        buffer.append('{"trait_type":"Total released","value":"', strTotalReleased, '"}]');
        return buffer.data;
    }
}
