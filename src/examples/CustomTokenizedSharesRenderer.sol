// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ITokenizedSharesRenderer} from "../TokenizedSharesRenderer.sol";

contract CustomTokenizedSharesRenderer is ITokenizedSharesRenderer {
    function render(RenderRequest calldata) external pure returns (string memory) {
        return "CUSTOM_RENDERING_RESULT";
    }
}
