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

    struct TokenizedShares {
        bytes backName;
        bytes backOffsets;
        bytes bordersName;
        bytes bordersOffsets;
        bytes stringAddress;
        bytes stringTotalReleased;
    }

    //--------------------------------------//
    //              RENDERERING             //
    //--------------------------------------//
    function render(RenderRequest calldata request) public view override returns (string memory) {
        TokenizedShares memory tokenizedShares;
        tokenizedShares.stringAddress = bytes(request.tokenizedShares.toHexStringChecksummed());
        tokenizedShares.stringTotalReleased = getStringTotalReleased(request.totalReleased);
        (tokenizedShares.backName, tokenizedShares.backOffsets) = getBack(request.tokenizedShares);
        (tokenizedShares.bordersName, tokenizedShares.bordersOffsets) = getBorders(request.totalReleased);

        DynamicBufferLib.DynamicBuffer memory jsonBuffer;
        jsonBuffer.append('{"name":"', bytes(request.name), '",');
        jsonBuffer.append('"description":"Tokenized Shares Id:', tokenizedShares.stringAddress, '",');
        jsonBuffer.append('"attributes":', buildAttributes(tokenizedShares), ",");
        jsonBuffer.append('"image":"data:image/svg+xml;base64,', buildImage(tokenizedShares), '"}');

        return string(abi.encodePacked("data:application/json;base64,", bytes(Base64.encode(jsonBuffer.data))));
    }

    function getStringTotalReleased(uint256 totalReleased) internal pure returns (bytes memory) {
        uint256 integer = totalReleased / 1e18;
        uint256 decimal = totalReleased - integer * 1e18;

        bytes memory strInteger = bytes(LibString.toString(integer));
        bytes memory strDecimal = bytes(LibString.toString(decimal));

        return abi.encodePacked(strInteger, ".", strDecimal);
    }

    function getBack(address tokenizedShares) internal pure returns (bytes memory name, bytes memory offsets) {
        uint256 pnrg = uint256(uint160(tokenizedShares)) % 10_000;

        if (pnrg > 9_900) {
            name = "Diamond";
            offsets =
                '<stop offset="0%" style="stop-color:#a0b0c0"/><stop offset="40%" style="stop-color:#FFFFFF"/><stop offset="60%" style="stop-color:#b0c0d0"/><stop offset="100%" style="stop-color:#a0b0c0"/>';
        } else if (pnrg > 9_750) {
            name = "Platinum";
            offsets =
                '<stop offset="0%" style="stop-color:#E0E0FF"/><stop offset="40%" style="stop-color:#FFFFFF"/><stop offset="60%" style="stop-color:#E0E0FF"/><stop offset="100%" style="stop-color:#B8B8C8"/>';
        } else if (pnrg > 9_550) {
            name = "Gold";
            offsets =
                '<stop offset="0%" style="stop-color:#CF9F20"/><stop offset="40%" style="stop-color:#FFFF00"/><stop offset="60%" style="stop-color:#B8860B"/><stop offset="100%" style="stop-color:#CF9F20"/>';
        } else if (pnrg > 9_300) {
            name = "Silver";
            offsets =
                '<stop offset="0%" style="stop-color:#AFAFAF"/><stop offset="40%" style="stop-color:#FFFFFF"/><stop offset="60%" style="stop-color:#B8B8B8"/><stop offset="100%" style="stop-color:#AFAFAF"/>';
        } else if (pnrg > 9_000) {
            name = "Bronze";
            offsets =
                '<stop offset="0%" style="stop-color:#7A3F10"/><stop offset="40%" style="stop-color:#FFA54F"/><stop offset="60%" style="stop-color:#A67D3D"/><stop offset="100%" style="stop-color:#7A3F10"/>';
        } else if (pnrg > 7_875) {
            name = "Opal";
            offsets =
                '<stop offset="0%" style="stop-color:#A8C3BC"/><stop offset="40%" style="stop-color:#D4FFFF"/><stop offset="60%" style="stop-color:#A8E4E2"/><stop offset="100%" style="stop-color:#A8C3BC"/>';
        } else if (pnrg > 6_750) {
            name = "Turquoise";
            offsets =
                '<stop offset="0%" style="stop-color:#006666"/><stop offset="40%" style="stop-color:#40e0d0"/><stop offset="60%" style="stop-color:#00ced1"/><stop offset="100%" style="stop-color:#006666"/>';
        } else if (pnrg > 5_625) {
            name = "Ruby";
            offsets =
                '<stop offset="0%" style="stop-color:#840012"/><stop offset="40%" style="stop-color:#ff0000"/><stop offset="60%" style="stop-color:#d10029"/><stop offset="100%" style="stop-color:#840012"/>';
        } else if (pnrg > 4_500) {
            name = "Emerald";
            offsets =
                '<stop offset="0%" style="stop-color:#087830"/><stop offset="40%" style="stop-color:#50c878"/><stop offset="60%" style="stop-color:#2e8b57"/><stop offset="100%" style="stop-color:#087830"/>';
        } else if (pnrg > 3_375) {
            name = "Sapphire";
            offsets =
                '<stop offset="0%" style="stop-color:#0d1a2b"/><stop offset="40%" style="stop-color:#0f52ba"/><stop offset="60%" style="stop-color:#1c3a5a"/><stop offset="100%" style="stop-color:#0d1a2b"/>';
        } else if (pnrg > 2_250) {
            name = "Amethist";
            offsets =
                '<stop offset="0%" style="stop-color:#5b3256"/><stop offset="40%" style="stop-color:#9b59b6"/><stop offset="60%" style="stop-color:#884d9e"/><stop offset="100%" style="stop-color:#5b3256"/>';
        } else {
            name = "Onyx";
            offsets =
                '<stop offset="0%" style="stop-color:#333333"/><stop offset="40%" style="stop-color:#666666"/><stop offset="60%" style="stop-color:#333333"/><stop offset="100%" style="stop-color:#333333"/>';
        }
    }

    function getBorders(uint256 totalReleased) internal pure returns (bytes memory name, bytes memory offsets) {
        if (totalReleased < 0.1 ether) {
            name = "Metal";
            offsets =
                '<stop offset="0%" style="stop-color:#7A7A7A"/><stop offset="40%" style="stop-color:#C0C0C0"/><stop offset="60%" style="stop-color:#A9A9A9"/><stop offset="100%" style="stop-color:#7A7A7A"/>';
        } else if (totalReleased < 1 ether) {
            name = "Bronze";
            offsets =
                '<stop offset="0%" style="stop-color:#7A3F10"/><stop offset="40%" style="stop-color:#FFA54F"/><stop offset="60%" style="stop-color:#A67D3D"/><stop offset="100%" style="stop-color:#7A3F10"/>';
        } else if (totalReleased < 10 ether) {
            name = "Silver";
            offsets =
                '<stop offset="0%" style="stop-color:#AFAFAF"/><stop offset="40%" style="stop-color:#FFFFFF"/><stop offset="60%" style="stop-color:#B8B8B8"/><stop offset="100%" style="stop-color:#AFAFAF"/>';
        } else if (totalReleased < 100 ether) {
            name = "Gold";
            offsets =
                '<stop offset="0%" style="stop-color:#CF9F20"/><stop offset="40%" style="stop-color:#FFFF00"/><stop offset="60%" style="stop-color:#B8860B"/><stop offset="100%" style="stop-color:#CF9F20"/>';
        } else {
            name = "Platinum";
            offsets =
                '<stop offset="0%" style="stop-color:#E0E0FF"/><stop offset="40%" style="stop-color:#FFFFFF"/><stop offset="60%" style="stop-color:#E0E0FF"/><stop offset="100%" style="stop-color:#B8B8C8"/>';
        }
    }

    function buildImage(TokenizedShares memory tokenizedShares) internal pure returns (bytes memory) {
        DynamicBufferLib.DynamicBuffer memory buffer;
        buffer.append(
            '<svg width="600" height="1050" viewBox="0 0 600 1050" xmlns="http://www.w3.org/2000/svg"><defs><path id="b" d="M 80 0 h 440 l 80 80 v890 a 80 80 0 0 1 -80 80 h -440 l -80 -80 v -890 a 80 80 0 0 1 80 -80 z"/><filter id="inner-shadow" x="-50%" y="-50%" width="200%" height="200%" filterUnits="userSpaceOnUse"><feComponentTransfer in="SourceAlpha"><feFuncA type="table" tableValues="1 0"/></feComponentTransfer><feGaussianBlur stdDeviation="5"/><feOffset dx="0" dy="5" result="offsetblur"/><feFlood flood-color="rgb(0, 0, 0)" result="color"/><feComposite in2="offsetblur" operator="in"/><feComposite in2="SourceAlpha" operator="in"/><feMerge><feMergeNode in="SourceGraphic"/><feMergeNode/></feMerge></filter><linearGradient id="back" x1="0%" y1="0%" x2="100%" y2="0%">',
            tokenizedShares.backOffsets
        );
        buffer.append(
            '</linearGradient><linearGradient id="borders" x1="0%" y1="0%" x2="100%" y2="0%">',
            tokenizedShares.bordersOffsets
        );
        buffer.append(
            '</linearGradient><g id="logo"><path d="M 20 0 h 110 l 20 20 h-110 a 20 20 0 0 0 -20 20 v 20 h -20 v-40 a 20 20 0 0 1 20 -20"/><path d="M 20 150 h 45 a 20 20 0 0 0 20 -20 v -100 a 20 20 0 0 0 -20 20 v 60 a 20 20 0 0 1 -20 20 h -45 l 20 20"/></g><g id="t"><path d="M 20 0 h 110 l 20 20 h-110 a 20 20 0 0 0 -20 20 v 20 h -20 v-40 a 20 20 0 0 1 20 -20"/><path d="M 66 150 a 20 20 0 0 0 20 -20 v -100 a 20 20 0 0 0 -20 20 v 100"/></g><g id="s"><path d="M 55 0 h 65 l 20 20 h-70 a 20 20 0 0 0 -20 20 v 20 h -20 v-40 a 20 20 0 0 1 20 -20 h 5"/><path d="M 20 150 h 45 a 20 20 0 0 0 20 -20 v -100 a 20 20 0 0 0 -20 20 v 60 a 20 20 0 0 1 -20 20 h -45 l 20 20"/></g><path id="address-path" d="M 560 750 v-900"/></defs><use href="#b" class="b0"/><use href="#b" class="b0 b1 inner-shadow"/><use href="#b" class="b2 inner-shadow"/><path d="m 15 425 h 109 a 200 200 0 1 1 0 200 h-109" class="b2 inner-shadow"/><circle cx="300" cy="525" r="150" class="b0 inner-shadow"/><use href="#logo" x="225" y="450" class="b2 inner-shadow"/><g id="top"><use href="#t" x="80" y="100" class="b0 inner-shadow"/><text x="180" y="250" class="back-text b0 inner-shadow">OKENIZED</text></g><g id="bottom"><use href="#s" x="80" y="100" class="b0 inner-shadow"/><text x="180" y="250" class="back-text b0 inner-shadow">HARES</text></g><text class="b0 address-text inner-shadow"><textPath href="#address-path">',
            tokenizedShares.stringAddress
        );
        buffer.append(
            "</textPath></text><style>.inner-shadow{filter:url(#inner-shadow)}.outer-shadow{filter:drop-shadow(-1px 1px 4px #000000)}.b0{fill:url(#borders)}.b1{transform-origin:center;transform:scale(95%)}.b2{fill:url(#back);transform-origin:center;transform:scale(90%)}.back-text{font-size:65px;font-family:system-ui,sans-serif}.address-text{font-size:20px;font-family:system-ui,sans-serif}#bottom{transform-origin:center;transform:rotate(180deg)}</style></svg>"
        );
        return bytes(Base64.encode(buffer.data));
    }

    function buildAttributes(TokenizedShares memory tokenizedShares) internal pure returns (bytes memory) {
        DynamicBufferLib.DynamicBuffer memory buffer;
        buffer.append('[{"trait_type":"Id","value":"', tokenizedShares.stringAddress, '"},');
        buffer.append('{"trait_type":"Total released","value":"', tokenizedShares.stringTotalReleased, '"},');
        buffer.append('{"trait_type":"Back","value":"', tokenizedShares.backName, '"},');
        buffer.append('{"trait_type":"Borders","value":"', tokenizedShares.bordersName, '"}]');
        return buffer.data;
    }
}
