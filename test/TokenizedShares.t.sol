// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {ITokenizedSharesRenderer, TokenizedSharesRenderer} from "../src/TokenizedSharesRenderer.sol";
import {ITokenizedShares, TokenizedShares} from "../src/TokenizedShares.sol";
import {ITokenizedSharesController, TokenizedSharesController} from "../src/TokenizedSharesController.sol";
import {ERC1155} from "solady/tokens/ERC1155.sol";

contract ERC1155Mock is ERC1155 {
    constructor(address to) {
        _mint(to, 0, 100, "");
        _mint(to, 1, 100, "");
    }

    function uri(uint256) public pure override returns (string memory) {
        return "";
    }
}

contract TokenizedSharesTest is Test {
    event ReceiveETH(uint256);
    event SharesReleased(address indexed tokenizedShares, address[] owners);
    event TransferSingle(
        address indexed operator, address indexed from, address indexed to, uint256 id, uint256 amount
    );
    event TransferBatch(
        address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] amounts
    );

    TokenizedSharesRenderer public renderer;
    TokenizedShares public implementation;
    TokenizedSharesController public controller;

    uint16 public keeperShares;
    address[] public recipients;
    uint16[] public shares;
    string public name = "TokenizedShares";
    string public symbol = "TOKS";
    TokenizedShares public tokenizedShares;

    function setUp() public {
        renderer = new TokenizedSharesRenderer(address(0), address(1), address(2), address(3));
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

        tokenizedShares = TokenizedShares(controller.addTokenizedShares(keeperShares, recipients, shares, name, symbol));
    }

    receive() external payable {}

    function testImmutables() public {
        assertEq(tokenizedShares.name(), name);
        assertEq(tokenizedShares.symbol(), symbol);
        assertEq(tokenizedShares.controller(), address(controller));
        assertEq(tokenizedShares.keeperShares(), keeperShares);
    }

    function testControllerMintShares() public {
        vm.expectRevert(ITokenizedShares.ITokenizedShares__NotSharesController.selector);
        tokenizedShares.controllerMintShares(recipients, shares);

        vm.prank(address(controller));
        vm.expectRevert(ITokenizedShares.ITokenizedShares__NoRecipients.selector);
        tokenizedShares.controllerMintShares(new address[](0), shares);

        vm.prank(address(controller));
        vm.expectRevert(ITokenizedShares.ITokenizedShares__ArrayLengthsMismatch.selector);
        tokenizedShares.controllerMintShares(recipients, new uint16[](0));

        vm.prank(address(controller));
        --shares[0];
        vm.expectRevert(ITokenizedShares.ITokenizedShares__InvalidSharesAmount.selector);
        tokenizedShares.controllerMintShares(recipients, shares);
    }

    function testControllerReleaseShares() public {
        vm.expectRevert(ITokenizedShares.ITokenizedShares__NotSharesController.selector);
        tokenizedShares.controllerReleaseShares(recipients);

        vm.prank(address(controller));
        vm.expectRevert(ITokenizedShares.ITokenizedShares__NoSharesOwners.selector);
        tokenizedShares.controllerReleaseShares(new address[](0));

        vm.prank(address(controller));
        vm.expectRevert(ITokenizedShares.ITokenizedShares__NoBalance.selector);
        tokenizedShares.controllerReleaseShares(recipients);
    }

    function testKeeperFees() public {
        assertEq(tokenizedShares.keeperFees(recipients), 0);

        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(1 ether);
        (bool success,) = (address(tokenizedShares)).call{value: 1 ether}("");
        assertTrue(success);

        assertEq(tokenizedShares.keeperFees(recipients), 1 ether * 1000 * 90 / 10000 / 100);
    }

    function testOwnerFees() public {
        assertEq(tokenizedShares.ownerFees(recipients), 0);

        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(1 ether);
        (bool success,) = (address(tokenizedShares)).call{value: 1 ether}("");
        assertTrue(success);

        assertEq(tokenizedShares.ownerFees(recipients), 1 ether * 1000 * 10 / 10000 / 100);
    }

    function testReleasable() public {
        uint256[] memory releasable = tokenizedShares.releasable(new address[](0));
        assertTrue(releasable.length == 0);

        releasable = tokenizedShares.releasable(recipients);
        assertEq(releasable[0], 0);
        assertEq(releasable[1], 0);
        assertEq(releasable[2], 0);

        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(1 ether);
        (bool success,) = (address(tokenizedShares)).call{value: 1 ether}("");
        assertTrue(success);

        releasable = tokenizedShares.releasable(recipients);
        assertEq(releasable[0], 0.63 ether);
        assertEq(releasable[1], 0.18 ether);
        assertEq(releasable[2], 0.09 ether);
    }

    function testTotalReleased() public {
        assertEq(tokenizedShares.totalReleased(), 0);

        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(1 ether);
        (bool success,) = (address(tokenizedShares)).call{value: 1 ether}("");
        assertTrue(success);

        vm.prank(address(controller));
        tokenizedShares.controllerReleaseShares(recipients);
        assertEq(tokenizedShares.totalReleased(), 1 ether);
    }

    function testSetCustomRenderer() public {
        assertEq(tokenizedShares.customRenderer(), address(0));

        vm.prank(recipients[1]);
        vm.expectRevert(ITokenizedShares.ITokenizedShares__NotMajorityShareholder.selector);
        tokenizedShares.setCustomRenderer(address(1));
        assertEq(tokenizedShares.customRenderer(), address(0));

        vm.prank(recipients[0]);
        tokenizedShares.setCustomRenderer(address(1));
        assertEq(tokenizedShares.customRenderer(), address(1));
    }

    function testOnERC1155Received() public {
        ERC1155Mock erc1155Mock = new ERC1155Mock(recipients[0]);

        vm.prank(recipients[0]);
        vm.expectRevert(ITokenizedShares.ITokenizedShares__InvalidDeposit.selector);
        erc1155Mock.safeTransferFrom(recipients[0], address(tokenizedShares), 0, 1, "");

        vm.prank(recipients[0]);
        vm.expectRevert(ITokenizedShares.ITokenizedShares__InvalidDeposit.selector);
        erc1155Mock.safeTransferFrom(recipients[0], address(tokenizedShares), 1, 1, "");

        vm.prank(recipients[0]);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(recipients[0], recipients[0], address(tokenizedShares), 0, 100);
        tokenizedShares.safeTransferFrom(recipients[0], address(tokenizedShares), 0, 100, "");
    }

    function testOnERC1155BatchReceived() public {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ERC1155Mock erc1155Mock = new ERC1155Mock(recipients[0]);

        ids[0] = 0;
        amounts[0] = 1;
        vm.prank(recipients[0]);
        vm.expectRevert(ITokenizedShares.ITokenizedShares__InvalidDeposit.selector);
        erc1155Mock.safeBatchTransferFrom(recipients[0], address(tokenizedShares), ids, amounts, "");

        ids[0] = 1;
        amounts[0] = 1;
        vm.prank(recipients[0]);
        vm.expectRevert(ITokenizedShares.ITokenizedShares__InvalidDeposit.selector);
        erc1155Mock.safeBatchTransferFrom(recipients[0], address(tokenizedShares), ids, amounts, "");

        ids[0] = 0;
        amounts[0] = 100;
        vm.prank(recipients[0]);
        vm.expectEmit(true, true, true, true);
        emit TransferBatch(recipients[0], recipients[0], address(tokenizedShares), ids, amounts);
        tokenizedShares.safeBatchTransferFrom(recipients[0], address(tokenizedShares), ids, amounts, "");
    }

    function testTransferDepositedShares() public {
        vm.expectRevert(ITokenizedShares.ITokenizedShares__NotMajorityShareholder.selector);
        tokenizedShares.transferDepositedShares(recipients[0], address(1), 100);

        vm.prank(recipients[0]);
        vm.expectRevert();
        tokenizedShares.transferDepositedShares(recipients[0], address(1), 100);

        TokenizedShares tokenizedShares2 = TokenizedShares(controller.addTokenizedShares(keeperShares, recipients, shares, name, symbol));
        vm.prank(recipients[0]);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(recipients[0], recipients[0], address(tokenizedShares), 0, 1_999);
        tokenizedShares2.safeTransferFrom(recipients[0], address(tokenizedShares), 0, 1_999, "");
        
        vm.prank(recipients[0]);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(address(tokenizedShares), address(tokenizedShares), recipients[0], 0, 1_999);
        tokenizedShares.transferDepositedShares(recipients[0], address(tokenizedShares2), 1_999);
    }

    function testSupportsInterface() public {
        assertTrue(tokenizedShares.supportsInterface(type(ITokenizedShares).interfaceId));
    }
}
