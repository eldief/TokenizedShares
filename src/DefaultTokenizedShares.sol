// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC1155TokenizedShares.sol";
import "solady/utils/Base64.sol";
import "solady/utils/SSTORE2.sol";
import "solady/utils/LibString.sol";
import "solady/utils/DynamicBufferLib.sol";

/**
 * @title DefaultTokenizedShares.
 * @author @eldief
 * @notice Default implementation of TokenizedShares.
 */
contract DefaultTokenizedShares is ERC1155TokenizedShares {
    using LibString for *;
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;

    //--------------------------------------//
    //               EVENTS                 //
    //--------------------------------------//

    /**
     * @notice ERC-4906 MetadataUpdate event.
     */
    event MetadataUpdate(uint256 _tokenId);

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
    //               GETTERS                //
    //--------------------------------------//

    function name() public pure returns (string memory) {
        return "Tokenized Shares";
    }

    function symbol() public pure returns (string memory) {
        return "TOKS";
    }

    //--------------------------------------//
    //              OVERRIDES               //
    //--------------------------------------//

    /**
     * @notice Overrides `ERC1155TokenizedShares.releaseShares`
     * @dev Add EIP-4906 MetadataUpdate event.
     */
    function releaseShares(address[] calldata owners) public override {
        super.releaseShares(owners);
        emit MetadataUpdate(0);
    }

    //--------------------------------------//
    //              RENDERERING             //
    //--------------------------------------//

    function uri(uint256) public view override returns (string memory) {
        TokenizedSharesStorage.Layout storage layout = TokenizedSharesStorage.layout();

        bytes memory strAddress = bytes(address(this).toHexStringChecksumed());
        bytes memory strTotalReleased = buildStrTotalReleased(layout);

        DynamicBufferLib.DynamicBuffer memory jsonBuffer;
        jsonBuffer.append('{"name":"', bytes(name()), '",');
        jsonBuffer.append('"description":"', bytes(name()), " Id: ", strAddress, '",');
        jsonBuffer.append('"attributes":', buildAttributes(strTotalReleased, strAddress), ",");
        jsonBuffer.append('"image":"data:image/svg+xml;base64,', buildImage(strTotalReleased, strAddress), '"}');

        return string(abi.encodePacked("data:application/json;base64,", bytes(Base64.encode(jsonBuffer.data))));
    }

    function buildStrTotalReleased(TokenizedSharesStorage.Layout storage layout) internal view returns (bytes memory) {
        uint256 released = _totalReleased(layout);
        uint256 integer = released / 1e18;
        uint256 decimal = (released - integer * 1e18);

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
