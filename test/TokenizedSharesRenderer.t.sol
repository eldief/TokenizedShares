// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {CustomTokenizedSharesRenderer} from "../src/examples/CustomTokenizedSharesRenderer.sol";
import {ITokenizedSharesRenderer, TokenizedSharesRenderer} from "../src/TokenizedSharesRenderer.sol";
import {ITokenizedShares, TokenizedShares} from "../src/TokenizedShares.sol";
import {ITokenizedSharesController, TokenizedSharesController} from "../src/TokenizedSharesController.sol";
import {ERC1155} from "solady/tokens/ERC1155.sol";
import {SSTORE2} from "solady/utils/SSTORE2.sol";

contract TokenizedSharesRendererTest is Test {
    TokenizedSharesRenderer public renderer;
    CustomTokenizedSharesRenderer public customRenderer;
    TokenizedShares public implementation;
    TokenizedSharesController public controller;

    uint16 public keeperShares;
    address[] public recipients;
    uint16[] public shares;
    string public name = "TokenizedShares";
    string public symbol = "TOKS";
    TokenizedShares public tokenizedShares;

    function setUp() public {
        customRenderer = new CustomTokenizedSharesRenderer();
        renderer = new TokenizedSharesRenderer();
        implementation = new TokenizedShares(address(renderer));
        controller = new TokenizedSharesController(address(implementation));

        keeperShares = 1_000;

        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        shares = new uint16[](3);
        shares[0] = 7_000;
        shares[1] = 2_000;
        shares[2] = 1_000;

        vm.prank(recipients[1]);
        tokenizedShares = TokenizedShares(controller.addTokenizedShares(keeperShares, recipients, shares, name, symbol));
        tokenizedShares = TokenizedShares(controller.addTokenizedShares(keeperShares, recipients, shares, name, symbol));
    }

    function testURI() public {
        string memory uri = TokenizedShares(tokenizedShares).uri(0);
        assertTrue(bytes(uri).length > 0);
        console.log(uri);

        vm.prank(recipients[0]);
        TokenizedShares(tokenizedShares).setCustomRenderer(address(customRenderer));
        assertEq(TokenizedShares(tokenizedShares).customRenderer(), address(customRenderer));

        uri = TokenizedShares(tokenizedShares).uri(0);
        assertTrue(bytes(uri).length > 0);
        assertEq(uri, "CUSTOM_RENDERING_RESULT");
    }
}
