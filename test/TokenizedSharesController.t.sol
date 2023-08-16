// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {ITokenizedSharesRenderer, TokenizedSharesRenderer} from "../src/TokenizedSharesRenderer.sol";
import {ITokenizedShares, TokenizedShares} from "../src/TokenizedShares.sol";
import {ITokenizedSharesController, TokenizedSharesController} from "../src/TokenizedSharesController.sol";

contract TokenizedSharesControllerTest is Test {
    event ReceiveETH(uint256);
    event NewTokenizedShares(
        address indexed tokenizedShares, uint16 keeperShares, address[] recipients, uint16[] shares
    );
    event SharesReleased(
        address[] indexed tokenizedShares,
        address keeper,
        uint256[] keepersShares,
        address[] accounts,
        uint256[][] releasedAmounts
    );

    TokenizedSharesRenderer public renderer;
    TokenizedShares public implementation;
    TokenizedSharesController public controller;

    string public name = "NAME";
    string public symbol = "SYMBOL";

    receive() external payable {}

    function setUp() public {
        renderer = new TokenizedSharesRenderer();
        implementation = new TokenizedShares(address(renderer));
        controller = new TokenizedSharesController(address(implementation));
    }

    function testAddTokenizedShares() public {
        address tokenizedShares;
        address[] memory recipients;
        uint16[] memory shares;

        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        shares = new uint16[](3);
        shares[0] = 7_000;
        shares[1] = 2_000;
        shares[2] = 1_000;

        vm.expectEmit(false, false, false, true);
        emit NewTokenizedShares(tokenizedShares, 0, recipients, shares);
        tokenizedShares = controller.addTokenizedShares(0, recipients, shares, name, symbol);

        assertEq(TokenizedShares(tokenizedShares).controller(), address(controller));
        assertEq(TokenizedShares(tokenizedShares).keeperShares(), 0);
        assertEq(TokenizedShares(tokenizedShares).name(), name);
        assertEq(TokenizedShares(tokenizedShares).symbol(), symbol);
        assertEq(TokenizedShares(tokenizedShares).balanceOf(recipients[0], 0), shares[0]);
        assertEq(TokenizedShares(tokenizedShares).balanceOf(recipients[1], 0), shares[1]);
        assertEq(TokenizedShares(tokenizedShares).balanceOf(recipients[2], 0), shares[2]);
    }

    function testAddTokenizedSharesWithKeeperShares() public {
        address tokenizedShares;
        uint16 keeperShares;
        address[] memory recipients;
        uint16[] memory shares;

        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        shares = new uint16[](3);
        shares[0] = 4_000;
        shares[1] = 4_000;
        shares[2] = 2_000;

        // keeper share too high
        keeperShares = 1001;
        vm.expectRevert(ITokenizedSharesController.ITokenizedSharesController__InvalidKeeperShares.selector);
        tokenizedShares = controller.addTokenizedShares(keeperShares, recipients, shares, name, symbol);

        // success
        keeperShares = 111;
        vm.expectEmit(false, false, false, true);
        emit NewTokenizedShares(tokenizedShares, keeperShares, recipients, shares);
        tokenizedShares = controller.addTokenizedShares(keeperShares, recipients, shares, name, symbol);

        assertEq(TokenizedShares(tokenizedShares).controller(), address(controller));
        assertEq(TokenizedShares(tokenizedShares).keeperShares(), keeperShares);
        assertEq(TokenizedShares(tokenizedShares).name(), name);
        assertEq(TokenizedShares(tokenizedShares).symbol(), symbol);
        assertEq(TokenizedShares(tokenizedShares).balanceOf(recipients[0], 0), shares[0]);
        assertEq(TokenizedShares(tokenizedShares).balanceOf(recipients[1], 0), shares[1]);
        assertEq(TokenizedShares(tokenizedShares).balanceOf(recipients[2], 0), shares[2]);
    }

    function testAddTokenizedSharesClones() public {
        uint16 keeperShares;
        address[] memory recipients;
        uint16[] memory shares;

        // 1st
        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        shares = new uint16[](3);
        shares[0] = 7_000;
        shares[1] = 2_000;
        shares[2] = 1_000;

        keeperShares = 111;

        vm.expectEmit(false, false, false, true);
        emit NewTokenizedShares(address(0), keeperShares, recipients, shares);
        address tokenizedShares = controller.addTokenizedShares(keeperShares, recipients, shares, name, symbol);

        assertEq(TokenizedShares(tokenizedShares).controller(), address(controller));
        assertEq(TokenizedShares(tokenizedShares).keeperShares(), keeperShares);
        assertEq(TokenizedShares(tokenizedShares).name(), name);
        assertEq(TokenizedShares(tokenizedShares).symbol(), symbol);
        assertEq(TokenizedShares(tokenizedShares).balanceOf(recipients[0], 0), shares[0]);
        assertEq(TokenizedShares(tokenizedShares).balanceOf(recipients[1], 0), shares[1]);
        assertEq(TokenizedShares(tokenizedShares).balanceOf(recipients[2], 0), shares[2]);

        // 2nd
        shares[0] = 7_000;
        shares[1] = 2_000;
        shares[2] = 1_000;

        keeperShares = 222;

        vm.expectEmit(false, false, false, true);
        emit NewTokenizedShares(tokenizedShares, keeperShares, recipients, shares);
        address tokenizedShares2 = controller.addTokenizedShares(keeperShares, recipients, shares, "NAME2", "SYMBOL2");

        assertTrue(tokenizedShares != tokenizedShares2);
        assertEq(TokenizedShares(tokenizedShares2).controller(), address(controller));
        assertEq(TokenizedShares(tokenizedShares2).keeperShares(), keeperShares);
        assertEq(TokenizedShares(tokenizedShares2).name(), "NAME2");
        assertEq(TokenizedShares(tokenizedShares2).symbol(), "SYMBOL2");
        assertEq(TokenizedShares(tokenizedShares2).balanceOf(recipients[0], 0), shares[0]);
        assertEq(TokenizedShares(tokenizedShares2).balanceOf(recipients[1], 0), shares[1]);
        assertEq(TokenizedShares(tokenizedShares2).balanceOf(recipients[2], 0), shares[2]);
    }

    function testReleaseShares_OnlySomeContracts() public {
        address[] memory recipients;
        address[] memory tokenizedShares;
        uint256[] memory keepersShares;
        uint256[][] memory releasedAmounts;

        // add tokenized share 1
        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");
        uint16[] memory clone0Shares = new uint16[](3);
        clone0Shares[0] = 6_000;
        clone0Shares[1] = 3_000;
        clone0Shares[2] = 1_000;
        address clone0 = controller.addTokenizedShares(0, recipients, clone0Shares, name, symbol);
        assertEq(clone0.balance, 0);

        // add tokenized share 1
        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");
        uint16[] memory clone1Shares = new uint16[](3);
        clone1Shares[0] = 6_000;
        clone1Shares[1] = 3_000;
        clone1Shares[2] = 1_000;
        address clone1 = controller.addTokenizedShares(0, recipients, clone1Shares, name, symbol);
        assertEq(clone1.balance, 0);

        // deposit to clone 1
        uint256 amount = 1 ether;
        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);
        (bool success,) = payable(clone1).call{value: amount}("");
        assertTrue(success);
        assertEq(clone1.balance, amount);

        // release shares from clone 1
        tokenizedShares = new address[](1);
        tokenizedShares[0] = clone1;
        keepersShares = new uint256[](1);
        keepersShares[0] = 0;
        releasedAmounts = new uint256[][](1);
        releasedAmounts[0] = new uint256[](3);
        releasedAmounts[0][0] = clone1.balance * clone1Shares[0] / 10_000;
        releasedAmounts[0][1] = clone1.balance * clone1Shares[1] / 10_000;
        releasedAmounts[0][2] = clone1.balance * clone1Shares[2] / 10_000;

        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, recipients, releasedAmounts);
        controller.releaseShares(recipients, tokenizedShares);
    }

    function testReleaseShares_DepositRelease() public {
        address[] memory recipients;
        address[] memory tokenizedShares;
        uint256[] memory keepersShares;
        address[] memory accounts;
        uint256[][] memory releasedAmounts;

        // no tokenized shares created
        tokenizedShares = new address[](0);
        keepersShares = new uint256[](0);
        accounts = new address[](0);
        releasedAmounts = new uint256[][](0);

        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(accounts);

        // add tokenized share
        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");
        uint16[] memory clone0Shares = new uint16[](3);
        clone0Shares[0] = 6_000;
        clone0Shares[1] = 3_000;
        clone0Shares[2] = 1_000;
        address clone0 = controller.addTokenizedShares(0, recipients, clone0Shares, name, symbol);
        assertEq(clone0.balance, 0);

        // no accounts
        tokenizedShares = new address[](1);
        tokenizedShares[0] = clone0;
        keepersShares = new uint256[](1);
        keepersShares[0] = 0;
        accounts = new address[](0);
        releasedAmounts = new uint256[][](1);
        releasedAmounts[0] = new uint256[](0);

        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(accounts);

        // no balance
        tokenizedShares = new address[](1);
        tokenizedShares[0] = clone0;
        keepersShares = new uint256[](1);
        keepersShares[0] = 0;
        accounts = new address[](3);
        accounts[0] = recipients[0];
        accounts[1] = recipients[1];
        accounts[2] = recipients[2];
        releasedAmounts = new uint256[][](1);
        releasedAmounts[0] = new uint256[](3);
        releasedAmounts[0][0] = 0;
        releasedAmounts[0][1] = 0;
        releasedAmounts[0][2] = 0;

        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(recipients);

        // release shares to clone 0
        uint256 amount = 1 ether;
        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);
        (bool success,) = payable(clone0).call{value: amount}("");
        assertTrue(success);
        assertEq(clone0.balance, amount);

        tokenizedShares = new address[](1);
        tokenizedShares[0] = clone0;
        keepersShares = new uint256[](1);
        keepersShares[0] = 0;
        accounts = new address[](3);
        accounts[0] = recipients[0];
        accounts[1] = recipients[1];
        accounts[2] = recipients[2];
        releasedAmounts = new uint256[][](1);
        releasedAmounts[0] = new uint256[](3);
        releasedAmounts[0][0] = clone0.balance * clone0Shares[0] / 10_000;
        releasedAmounts[0][1] = clone0.balance * clone0Shares[1] / 10_000;
        releasedAmounts[0][2] = clone0.balance * clone0Shares[2] / 10_000;

        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(recipients);

        // nothing left to release
        releasedAmounts[0][0] = 0;
        releasedAmounts[0][1] = 0;
        releasedAmounts[0][2] = 0;

        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(recipients);

        // add tokenized share
        uint16[] memory clone1Shares = new uint16[](3);
        clone1Shares[0] = 6_000;
        clone1Shares[1] = 3_000;
        clone1Shares[2] = 1_000;
        address clone1 = controller.addTokenizedShares(0, recipients, clone1Shares, name, symbol);
        assertEq(clone1.balance, 0);
        (success,) = payable(clone1).call{value: 0.33 ether}("");
        assertTrue(success);
        assertEq(clone1.balance, 0.33 ether);

        // add tokenized share
        uint16[] memory clone2Shares = new uint16[](3);
        clone2Shares[0] = 6_000;
        clone2Shares[1] = 3_000;
        clone2Shares[2] = 1_000;
        address clone2 = controller.addTokenizedShares(0, recipients, clone2Shares, name, symbol);
        assertEq(clone2.balance, 0);
        (success,) = payable(clone2).call{value: 0.66 ether}("");
        assertTrue(success);
        assertEq(clone2.balance, 0.66 ether);

        // release shares to all clones 0, 1, 2
        tokenizedShares = new address[](3);
        tokenizedShares[0] = clone0;
        tokenizedShares[1] = clone1;
        tokenizedShares[2] = clone2;
        keepersShares = new uint256[](3);
        keepersShares[0] = 0;
        keepersShares[1] = 0;
        keepersShares[2] = 0;
        releasedAmounts = new uint256[][](3);
        releasedAmounts[0] = new uint256[](3);
        releasedAmounts[0][0] = clone0.balance * clone0Shares[0] / 10_000;
        releasedAmounts[0][1] = clone0.balance * clone0Shares[1] / 10_000;
        releasedAmounts[0][2] = clone0.balance * clone0Shares[2] / 10_000;
        releasedAmounts[1] = new uint256[](3);
        releasedAmounts[1][0] = clone1.balance * clone1Shares[0] / 10_000;
        releasedAmounts[1][1] = clone1.balance * clone1Shares[1] / 10_000;
        releasedAmounts[1][2] = clone1.balance * clone1Shares[2] / 10_000;
        releasedAmounts[2] = new uint256[](3);
        releasedAmounts[2][0] = clone2.balance * clone2Shares[0] / 10_000;
        releasedAmounts[2][1] = clone2.balance * clone2Shares[1] / 10_000;
        releasedAmounts[2][2] = clone2.balance * clone2Shares[2] / 10_000;

        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(recipients);
    }

    function testReleaseShares_DepositReleaseDepositRelease() public {
        address[] memory recipients;
        address[] memory tokenizedShares;
        uint256[] memory keepersShares;
        address[] memory accounts;
        uint256[][] memory releasedAmounts;

        // add tokenized share
        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");
        uint16[] memory clone0Shares = new uint16[](3);
        clone0Shares[0] = 6_000;
        clone0Shares[1] = 3_000;
        clone0Shares[2] = 1_000;
        address clone0 = controller.addTokenizedShares(0, recipients, clone0Shares, name, symbol);
        assertEq(clone0.balance, 0);

        // deposit
        uint256 amount = 1 ether;
        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);
        (bool success,) = payable(clone0).call{value: amount}("");
        assertTrue(success);
        assertEq(clone0.balance, amount);

        // release shares to clone 0
        tokenizedShares = new address[](1);
        tokenizedShares[0] = clone0;
        keepersShares = new uint256[](1);
        keepersShares[0] = 0;
        accounts = new address[](3);
        accounts[0] = recipients[0];
        accounts[1] = recipients[1];
        accounts[2] = recipients[2];
        releasedAmounts = new uint256[][](1);
        releasedAmounts[0] = new uint256[](3);
        releasedAmounts[0][0] = clone0.balance * clone0Shares[0] / 10_000;
        releasedAmounts[0][1] = clone0.balance * clone0Shares[1] / 10_000;
        releasedAmounts[0][2] = clone0.balance * clone0Shares[2] / 10_000;

        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(recipients);
        assertEq(clone0.balance, 0);

        // deposit
        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);
        (success,) = payable(clone0).call{value: amount}("");
        assertTrue(success);
        assertEq(clone0.balance, amount);

        // release shares to clone 0
        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(recipients);
        assertEq(clone0.balance, 0);
    }

    function testReleaseShares_DepositTransferRelease() public {
        address[] memory recipients;
        address[] memory tokenizedShares;
        uint256[] memory keepersShares;
        address[] memory accounts;
        uint256[][] memory releasedAmounts;

        // add tokenized share
        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");
        uint16[] memory clone0Shares = new uint16[](3);
        clone0Shares[0] = 6_000;
        clone0Shares[1] = 3_000;
        clone0Shares[2] = 1_000;
        address clone0 = controller.addTokenizedShares(0, recipients, clone0Shares, name, symbol);
        assertEq(clone0.balance, 0);

        // deposit
        uint256 amount = 1 ether;
        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);
        (bool success,) = payable(clone0).call{value: amount}("");
        assertTrue(success);
        assertEq(clone0.balance, amount);

        // transfer
        address recipient3 = makeAddr("recipient_3");
        vm.prank(recipients[0]);
        TokenizedShares(clone0).safeTransferFrom(recipients[0], recipient3, 0, 3_000, "");

        // release shares to clone 0
        tokenizedShares = new address[](1);
        tokenizedShares[0] = clone0;
        keepersShares = new uint256[](1);
        keepersShares[0] = 0;
        accounts = new address[](4);
        accounts[0] = recipients[0];
        accounts[1] = recipients[1];
        accounts[2] = recipients[2];
        accounts[3] = recipient3;
        releasedAmounts = new uint256[][](1);
        releasedAmounts[0] = new uint256[](4);
        releasedAmounts[0][0] = clone0.balance * 3_000 / 10_000;
        releasedAmounts[0][1] = clone0.balance * clone0Shares[1] / 10_000;
        releasedAmounts[0][2] = clone0.balance * clone0Shares[2] / 10_000;
        releasedAmounts[0][3] = clone0.balance * 3_000 / 10_000;

        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(accounts);
        assertEq(clone0.balance, 0);
    }

    function testReleaseShares_DepositReleaseTransferDepositRelease() public {
        address[] memory recipients;
        address[] memory tokenizedShares;
        uint256[] memory keepersShares;
        address[] memory accounts;
        uint256[][] memory releasedAmounts;

        // add tokenized share
        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");
        uint16[] memory clone0Shares = new uint16[](3);
        clone0Shares[0] = 6_000;
        clone0Shares[1] = 3_000;
        clone0Shares[2] = 1_000;
        address clone0 = controller.addTokenizedShares(0, recipients, clone0Shares, name, symbol);
        assertEq(clone0.balance, 0);

        // deposit
        uint256 amount = 1 ether;
        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);
        (bool success,) = payable(clone0).call{value: amount}("");
        assertTrue(success);
        assertEq(clone0.balance, amount);

        // release
        tokenizedShares = new address[](1);
        tokenizedShares[0] = clone0;
        keepersShares = new uint256[](1);
        keepersShares[0] = 0;
        accounts = new address[](3);
        accounts[0] = recipients[0];
        accounts[1] = recipients[1];
        accounts[2] = recipients[2];
        releasedAmounts = new uint256[][](1);
        releasedAmounts[0] = new uint256[](3);
        releasedAmounts[0][0] = clone0.balance * clone0Shares[0] / 10_000;
        releasedAmounts[0][1] = clone0.balance * clone0Shares[1] / 10_000;
        releasedAmounts[0][2] = clone0.balance * clone0Shares[2] / 10_000;

        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(recipients);

        // transfer
        address recipient3 = makeAddr("recipient_3");
        vm.prank(recipients[0]);
        TokenizedShares(clone0).safeTransferFrom(recipients[0], recipient3, 0, 3_000, "");

        // deposit
        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);
        (success,) = payable(clone0).call{value: amount}("");
        assertTrue(success);
        assertEq(clone0.balance, amount);

        // release
        tokenizedShares = new address[](1);
        tokenizedShares[0] = clone0;
        keepersShares = new uint256[](1);
        keepersShares[0] = 0;
        accounts = new address[](4);
        accounts[0] = recipients[0];
        accounts[1] = recipients[1];
        accounts[2] = recipients[2];
        accounts[3] = recipient3;
        releasedAmounts = new uint256[][](1);
        releasedAmounts[0] = new uint256[](4);
        releasedAmounts[0][0] = clone0.balance * 3_000 / 10_000;
        releasedAmounts[0][1] = clone0.balance * clone0Shares[1] / 10_000;
        releasedAmounts[0][2] = clone0.balance * clone0Shares[2] / 10_000;
        releasedAmounts[0][3] = clone0.balance * 3_000 / 10_000;

        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(accounts);
        assertEq(clone0.balance, 0);
    }

    function testReleaseShares_DepositReleaseDepositTransferRelease() public {
        address[] memory recipients;
        address[] memory tokenizedShares;
        uint256[] memory keepersShares;
        address[] memory accounts;
        uint256[][] memory releasedAmounts;

        // add tokenized share
        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");
        uint16[] memory clone0Shares = new uint16[](3);
        clone0Shares[0] = 6_000;
        clone0Shares[1] = 3_000;
        clone0Shares[2] = 1_000;
        address clone0 = controller.addTokenizedShares(0, recipients, clone0Shares, name, symbol);
        assertEq(clone0.balance, 0);

        // deposit
        uint256 amount = 1 ether;
        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);
        (bool success,) = payable(clone0).call{value: amount}("");
        assertTrue(success);
        assertEq(clone0.balance, amount);

        // release
        tokenizedShares = new address[](1);
        tokenizedShares[0] = clone0;
        keepersShares = new uint256[](1);
        keepersShares[0] = 0;
        accounts = new address[](3);
        accounts[0] = recipients[0];
        accounts[1] = recipients[1];
        accounts[2] = recipients[2];
        releasedAmounts = new uint256[][](1);
        releasedAmounts[0] = new uint256[](3);
        releasedAmounts[0][0] = clone0.balance * clone0Shares[0] / 10_000;
        releasedAmounts[0][1] = clone0.balance * clone0Shares[1] / 10_000;
        releasedAmounts[0][2] = clone0.balance * clone0Shares[2] / 10_000;

        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(recipients);

        // deposit
        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);
        (success,) = payable(clone0).call{value: amount}("");
        assertTrue(success);
        assertEq(clone0.balance, amount);

        // transfer
        address recipient3 = makeAddr("recipient_3");
        vm.prank(recipients[0]);
        TokenizedShares(clone0).safeTransferFrom(recipients[0], recipient3, 0, 3_000, "");

        // release
        tokenizedShares = new address[](1);
        tokenizedShares[0] = clone0;
        keepersShares = new uint256[](1);
        keepersShares[0] = 0;
        accounts = new address[](4);
        accounts[0] = recipients[0];
        accounts[1] = recipients[1];
        accounts[2] = recipients[2];
        accounts[3] = recipient3;
        releasedAmounts = new uint256[][](1);
        releasedAmounts[0] = new uint256[](4);
        releasedAmounts[0][0] = clone0.balance * 3_000 / 10_000;
        releasedAmounts[0][1] = clone0.balance * clone0Shares[1] / 10_000;
        releasedAmounts[0][2] = clone0.balance * clone0Shares[2] / 10_000;
        releasedAmounts[0][3] = clone0.balance * 3_000 / 10_000;

        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(accounts);
        assertEq(clone0.balance, 0);
    }

    function testReleaseShares_WithKeeperShares_DepositRelease() public {
        address[] memory recipients;
        address[] memory tokenizedShares;
        uint256[] memory keepersShares;
        address[] memory accounts;
        uint256[][] memory releasedAmounts;

        // no tokenized shares created
        tokenizedShares = new address[](0);
        keepersShares = new uint256[](0);
        accounts = new address[](0);
        releasedAmounts = new uint256[][](0);

        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(accounts);

        // add tokenized share 0
        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");
        uint16[] memory clone0Shares = new uint16[](3);
        clone0Shares[0] = 5_000;
        clone0Shares[1] = 3_000;
        clone0Shares[2] = 2_000;
        address clone0 = controller.addTokenizedShares(1_000, recipients, clone0Shares, name, symbol);
        assertEq(clone0.balance, 0);

        // no accounts
        tokenizedShares = new address[](1);
        tokenizedShares[0] = clone0;
        keepersShares = new uint256[](1);
        keepersShares[0] = 0;
        accounts = new address[](0);
        releasedAmounts = new uint256[][](1);
        releasedAmounts[0] = new uint256[](0);

        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(accounts);

        // no balance
        tokenizedShares = new address[](1);
        tokenizedShares[0] = clone0;
        keepersShares = new uint256[](1);
        keepersShares[0] = 0;
        accounts = new address[](3);
        accounts[0] = recipients[0];
        accounts[1] = recipients[1];
        accounts[2] = recipients[2];
        releasedAmounts = new uint256[][](1);
        releasedAmounts[0] = new uint256[](3);
        releasedAmounts[0][0] = 0;
        releasedAmounts[0][1] = 0;
        releasedAmounts[0][2] = 0;

        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(recipients);

        // deposit
        uint256 amount = 1 ether;
        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);
        (bool success,) = payable(clone0).call{value: amount}("");
        assertTrue(success);
        assertEq(clone0.balance, amount);

        // release shares to clone 0
        tokenizedShares = new address[](1);
        tokenizedShares[0] = clone0;
        keepersShares = new uint256[](1);
        keepersShares[0] = clone0.balance * 1_000 * 90 / 100 / 10_000;
        accounts = new address[](3);
        accounts[0] = recipients[0];
        accounts[1] = recipients[1];
        accounts[2] = recipients[2];
        releasedAmounts = new uint256[][](1);
        releasedAmounts[0] = new uint256[](3);
        releasedAmounts[0][0] =
            clone0.balance * clone0Shares[0] / 10_000 - clone0.balance * clone0Shares[0] / 10_000 * 1_000 / 10_000;
        releasedAmounts[0][1] =
            clone0.balance * clone0Shares[1] / 10_000 - clone0.balance * clone0Shares[1] / 10_000 * 1_000 / 10_000;
        releasedAmounts[0][2] =
            clone0.balance * clone0Shares[2] / 10_000 - clone0.balance * clone0Shares[2] / 10_000 * 1_000 / 10_000;

        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(recipients);

        // nothing left to release
        releasedAmounts[0][0] = 0;
        releasedAmounts[0][1] = 0;
        releasedAmounts[0][2] = 0;

        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(recipients);

        // add tokenized share 1 and deposit
        uint16[] memory clone1Shares = new uint16[](3);
        clone1Shares[0] = 2_000;
        clone1Shares[1] = 1_000;
        clone1Shares[2] = 7_000;
        address clone1 = controller.addTokenizedShares(420, recipients, clone1Shares, name, symbol);
        assertEq(clone1.balance, 0);
        (success,) = payable(clone1).call{value: 0.33 ether}("");
        assertTrue(success);
        assertEq(clone1.balance, 0.33 ether);

        // add tokenized share 2 and deposit
        uint16[] memory clone2Shares = new uint16[](3);
        clone2Shares[0] = 3_000;
        clone2Shares[1] = 3_000;
        clone2Shares[2] = 4_000;
        address clone2 = controller.addTokenizedShares(69, recipients, clone2Shares, name, symbol);
        assertEq(clone2.balance, 0);
        (success,) = payable(clone2).call{value: 0.66 ether}("");
        assertTrue(success);
        assertEq(clone2.balance, 0.66 ether);

        // release shares to all clones 0, 1, 2
        tokenizedShares = new address[](3);
        tokenizedShares[0] = clone0;
        tokenizedShares[1] = clone1;
        tokenizedShares[2] = clone2;
        keepersShares = new uint256[](3);
        keepersShares[0] = clone0.balance * 1_000 * 90 / 100 / 10_000;
        keepersShares[1] = clone1.balance * 420 * 90 / 100 / 10_000;
        keepersShares[2] = clone2.balance * 69 * 90 / 100 / 10_000;
        releasedAmounts = new uint256[][](3);
        releasedAmounts[0] = new uint256[](3);
        releasedAmounts[0][0] =
            clone0.balance * clone0Shares[0] / 10_000 - clone0.balance * clone0Shares[0] / 10_000 * 1_000 / 10_000;
        releasedAmounts[0][1] =
            clone0.balance * clone0Shares[1] / 10_000 - clone0.balance * clone0Shares[1] / 10_000 * 1_000 / 10_000;
        releasedAmounts[0][2] =
            clone0.balance * clone0Shares[2] / 10_000 - clone0.balance * clone0Shares[2] / 10_000 * 1_000 / 10_000;
        releasedAmounts[1] = new uint256[](3);
        releasedAmounts[1][0] =
            clone1.balance * clone1Shares[0] / 10_000 - clone1.balance * clone1Shares[0] / 10_000 * 420 / 10_000;
        releasedAmounts[1][1] =
            clone1.balance * clone1Shares[1] / 10_000 - clone1.balance * clone1Shares[1] / 10_000 * 420 / 10_000;
        releasedAmounts[1][2] =
            clone1.balance * clone1Shares[2] / 10_000 - clone1.balance * clone1Shares[2] / 10_000 * 420 / 10_000;
        releasedAmounts[2] = new uint256[](3);
        releasedAmounts[2][0] =
            clone2.balance * clone2Shares[0] / 10_000 - clone2.balance * clone2Shares[0] / 10_000 * 69 / 10_000;
        releasedAmounts[2][1] =
            clone2.balance * clone2Shares[1] / 10_000 - clone2.balance * clone2Shares[1] / 10_000 * 69 / 10_000;
        releasedAmounts[2][2] =
            clone2.balance * clone2Shares[2] / 10_000 - clone2.balance * clone2Shares[2] / 10_000 * 69 / 10_000;

        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(recipients);
    }

    function testReleaseShares_WithKeeperShares_DepositReleaseDepositRelease() public {
        address[] memory recipients;
        address[] memory tokenizedShares;
        uint256[] memory keepersShares;
        address[] memory accounts;
        uint256[][] memory releasedAmounts;

        // add tokenized share 0
        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");
        uint16[] memory clone0Shares = new uint16[](3);
        clone0Shares[0] = 5_000;
        clone0Shares[1] = 3_000;
        clone0Shares[2] = 2_000;
        address clone0 = controller.addTokenizedShares(1_000, recipients, clone0Shares, name, symbol);
        assertEq(clone0.balance, 0);

        // deposit
        uint256 amount = 1 ether;
        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);
        (bool success,) = payable(clone0).call{value: amount}("");
        assertTrue(success);
        assertEq(clone0.balance, amount);

        // release
        tokenizedShares = new address[](1);
        tokenizedShares[0] = clone0;
        keepersShares = new uint256[](1);
        keepersShares[0] = clone0.balance * 1_000 * 90 / 100 / 10_000;
        accounts = new address[](3);
        accounts[0] = recipients[0];
        accounts[1] = recipients[1];
        accounts[2] = recipients[2];
        releasedAmounts = new uint256[][](1);
        releasedAmounts[0] = new uint256[](3);
        releasedAmounts[0][0] =
            clone0.balance * clone0Shares[0] / 10_000 - clone0.balance * clone0Shares[0] / 10_000 * 1_000 / 10_000;
        releasedAmounts[0][1] =
            clone0.balance * clone0Shares[1] / 10_000 - clone0.balance * clone0Shares[1] / 10_000 * 1_000 / 10_000;
        releasedAmounts[0][2] =
            clone0.balance * clone0Shares[2] / 10_000 - clone0.balance * clone0Shares[2] / 10_000 * 1_000 / 10_000;

        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(recipients);

        // deposit
        amount = 1 ether;
        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);
        (success,) = payable(clone0).call{value: amount}("");
        assertTrue(success);
        assertEq(clone0.balance, amount);

        // release
        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(recipients);
    }

    function testReleaseShares_WithKeeperShares_DepositTransferRelease() public {
        address[] memory recipients;
        address[] memory tokenizedShares;
        uint256[] memory keepersShares;
        address[] memory accounts;
        uint256[][] memory releasedAmounts;

        // add tokenized share 0
        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");
        uint16[] memory clone0Shares = new uint16[](3);
        clone0Shares[0] = 5_000;
        clone0Shares[1] = 3_000;
        clone0Shares[2] = 2_000;
        address clone0 = controller.addTokenizedShares(1_000, recipients, clone0Shares, name, symbol);
        assertEq(clone0.balance, 0);

        // deposit
        uint256 amount = 1 ether;
        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);
        (bool success,) = payable(clone0).call{value: amount}("");
        assertTrue(success);
        assertEq(clone0.balance, amount);

        // transfer
        address recipient3 = makeAddr("recipient_3");
        vm.prank(recipients[0]);
        TokenizedShares(clone0).safeTransferFrom(recipients[0], recipient3, 0, 3_000, "");

        // release
        tokenizedShares = new address[](1);
        tokenizedShares[0] = clone0;
        keepersShares = new uint256[](1);
        keepersShares[0] = clone0.balance * 1_000 * 90 / 100 / 10_000;
        accounts = new address[](4);
        accounts[0] = recipients[0];
        accounts[1] = recipients[1];
        accounts[2] = recipients[2];
        accounts[3] = recipient3;
        releasedAmounts = new uint256[][](1);
        releasedAmounts[0] = new uint256[](4);
        releasedAmounts[0][0] = clone0.balance * 2_000 / 10_000 - clone0.balance * 2_000 / 10_000 * 1_000 / 10_000;
        releasedAmounts[0][1] =
            clone0.balance * clone0Shares[1] / 10_000 - clone0.balance * clone0Shares[1] / 10_000 * 1_000 / 10_000;
        releasedAmounts[0][2] =
            clone0.balance * clone0Shares[2] / 10_000 - clone0.balance * clone0Shares[2] / 10_000 * 1_000 / 10_000;
        releasedAmounts[0][3] = clone0.balance * 3_000 / 10_000 - clone0.balance * 3_000 / 10_000 * 1_000 / 10_000;

        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(accounts);
    }

    function testReleaseShares_WithKeeperShares_DepositReleaseTransferDepositRelease() public {
        address[] memory recipients;
        address[] memory tokenizedShares;
        uint256[] memory keepersShares;
        address[] memory accounts;
        uint256[][] memory releasedAmounts;

        // add tokenized share 0
        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");
        uint16[] memory clone0Shares = new uint16[](3);
        clone0Shares[0] = 5_000;
        clone0Shares[1] = 3_000;
        clone0Shares[2] = 2_000;
        address clone0 = controller.addTokenizedShares(1_000, recipients, clone0Shares, name, symbol);
        assertEq(clone0.balance, 0);

        // deposit
        uint256 amount = 1 ether;
        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);
        (bool success,) = payable(clone0).call{value: amount}("");
        assertTrue(success);
        assertEq(clone0.balance, amount);

        // release
        tokenizedShares = new address[](1);
        tokenizedShares[0] = clone0;
        keepersShares = new uint256[](1);
        keepersShares[0] = clone0.balance * 1_000 * 90 / 100 / 10_000;
        accounts = new address[](3);
        accounts[0] = recipients[0];
        accounts[1] = recipients[1];
        accounts[2] = recipients[2];
        releasedAmounts = new uint256[][](1);
        releasedAmounts[0] = new uint256[](3);
        releasedAmounts[0][0] =
            clone0.balance * clone0Shares[0] / 10_000 - clone0.balance * clone0Shares[0] / 10_000 * 1_000 / 10_000;
        releasedAmounts[0][1] =
            clone0.balance * clone0Shares[1] / 10_000 - clone0.balance * clone0Shares[1] / 10_000 * 1_000 / 10_000;
        releasedAmounts[0][2] =
            clone0.balance * clone0Shares[2] / 10_000 - clone0.balance * clone0Shares[2] / 10_000 * 1_000 / 10_000;

        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(recipients);

        // transfer
        address recipient3 = makeAddr("recipient_3");
        vm.prank(recipients[0]);
        TokenizedShares(clone0).safeTransferFrom(recipients[0], recipient3, 0, 3_000, "");

        // deposit
        amount = 1 ether;
        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);
        (success,) = payable(clone0).call{value: amount}("");
        assertTrue(success);
        assertEq(clone0.balance, amount);

        // release
        tokenizedShares = new address[](1);
        tokenizedShares[0] = clone0;
        keepersShares = new uint256[](1);
        keepersShares[0] = clone0.balance * 1_000 * 90 / 100 / 10_000;
        accounts = new address[](4);
        accounts[0] = recipients[0];
        accounts[1] = recipients[1];
        accounts[2] = recipients[2];
        accounts[3] = recipient3;
        releasedAmounts = new uint256[][](1);
        releasedAmounts[0] = new uint256[](4);
        releasedAmounts[0][0] = clone0.balance * 2_000 / 10_000 - clone0.balance * 2_000 / 10_000 * 1_000 / 10_000;
        releasedAmounts[0][1] =
            clone0.balance * clone0Shares[1] / 10_000 - clone0.balance * clone0Shares[1] / 10_000 * 1_000 / 10_000;
        releasedAmounts[0][2] =
            clone0.balance * clone0Shares[2] / 10_000 - clone0.balance * clone0Shares[2] / 10_000 * 1_000 / 10_000;
        releasedAmounts[0][3] = clone0.balance * 3_000 / 10_000 - clone0.balance * 3_000 / 10_000 * 1_000 / 10_000;

        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(accounts);
    }

    function testReleaseShares_WithKeeperShares_DepositReleaseDepositTransferRelease() public {
        address[] memory recipients;
        address[] memory tokenizedShares;
        uint256[] memory keepersShares;
        address[] memory accounts;
        uint256[][] memory releasedAmounts;

        // add tokenized share 0
        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");
        uint16[] memory clone0Shares = new uint16[](3);
        clone0Shares[0] = 5_000;
        clone0Shares[1] = 3_000;
        clone0Shares[2] = 2_000;
        address clone0 = controller.addTokenizedShares(1_000, recipients, clone0Shares, name, symbol);
        assertEq(clone0.balance, 0);

        // deposit
        uint256 amount = 1 ether;
        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);
        (bool success,) = payable(clone0).call{value: amount}("");
        assertTrue(success);
        assertEq(clone0.balance, amount);

        // release
        tokenizedShares = new address[](1);
        tokenizedShares[0] = clone0;
        keepersShares = new uint256[](1);
        keepersShares[0] = clone0.balance * 1_000 * 90 / 100 / 10_000;
        accounts = new address[](3);
        accounts[0] = recipients[0];
        accounts[1] = recipients[1];
        accounts[2] = recipients[2];
        releasedAmounts = new uint256[][](1);
        releasedAmounts[0] = new uint256[](3);
        releasedAmounts[0][0] =
            clone0.balance * clone0Shares[0] / 10_000 - clone0.balance * clone0Shares[0] / 10_000 * 1_000 / 10_000;
        releasedAmounts[0][1] =
            clone0.balance * clone0Shares[1] / 10_000 - clone0.balance * clone0Shares[1] / 10_000 * 1_000 / 10_000;
        releasedAmounts[0][2] =
            clone0.balance * clone0Shares[2] / 10_000 - clone0.balance * clone0Shares[2] / 10_000 * 1_000 / 10_000;

        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(recipients);

        // deposit
        amount = 1 ether;
        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);
        (success,) = payable(clone0).call{value: amount}("");
        assertTrue(success);
        assertEq(clone0.balance, amount);

        // transfer
        address recipient3 = makeAddr("recipient_3");
        vm.prank(recipients[0]);
        TokenizedShares(clone0).safeTransferFrom(recipients[0], recipient3, 0, 3_000, "");

        // release
        tokenizedShares = new address[](1);
        tokenizedShares[0] = clone0;
        keepersShares = new uint256[](1);
        keepersShares[0] = clone0.balance * 1_000 * 90 / 100 / 10_000;
        accounts = new address[](4);
        accounts[0] = recipients[0];
        accounts[1] = recipients[1];
        accounts[2] = recipients[2];
        accounts[3] = recipient3;
        releasedAmounts = new uint256[][](1);
        releasedAmounts[0] = new uint256[](4);
        releasedAmounts[0][0] = clone0.balance * 2_000 / 10_000 - clone0.balance * 2_000 / 10_000 * 1_000 / 10_000;
        releasedAmounts[0][1] =
            clone0.balance * clone0Shares[1] / 10_000 - clone0.balance * clone0Shares[1] / 10_000 * 1_000 / 10_000;
        releasedAmounts[0][2] =
            clone0.balance * clone0Shares[2] / 10_000 - clone0.balance * clone0Shares[2] / 10_000 * 1_000 / 10_000;
        releasedAmounts[0][3] = clone0.balance * 3_000 / 10_000 - clone0.balance * 3_000 / 10_000 * 1_000 / 10_000;

        vm.expectEmit(true, false, false, true);
        emit SharesReleased(tokenizedShares, tx.origin, keepersShares, accounts, releasedAmounts);
        controller.releaseShares(accounts);
    }

    function testKeeperFees() public {
        address[] memory recipients;

        // add tokenized share 0
        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");
        uint16[] memory clone0Shares = new uint16[](3);
        clone0Shares[0] = 5_000;
        clone0Shares[1] = 3_000;
        clone0Shares[2] = 2_000;
        address clone0 = controller.addTokenizedShares(1_000, recipients, clone0Shares, name, symbol);
        assertEq(clone0.balance, 0);

        // deposit
        uint256 amount = 1 ether;
        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);
        (bool success,) = payable(clone0).call{value: amount}("");
        assertTrue(success);
        assertEq(clone0.balance, amount);

        (address[] memory addresses, uint256[] memory amounts) = controller.keeperFees(recipients);
        assertTrue(addresses.length == 1);
        assertTrue(addresses[0] == clone0);
        assertTrue(amounts.length == 1);
        assertTrue(amounts[0] == 0.09 ether);

        // add tokenized share 1
        uint16[] memory clone1Shares = new uint16[](3);
        clone1Shares[0] = 5_000;
        clone1Shares[1] = 3_000;
        clone1Shares[2] = 2_000;
        address clone1 = controller.addTokenizedShares(1_000, recipients, clone1Shares, name, symbol);
        assertEq(clone1.balance, 0);

        (addresses, amounts) = controller.keeperFees(recipients);
        assertTrue(addresses.length == 2);
        assertTrue(addresses[0] == clone0);
        assertTrue(addresses[1] == clone1);
        assertTrue(amounts.length == 2);
        assertTrue(amounts[0] == 0.09 ether);
        assertTrue(amounts[1] == 0);

        // deposit
        amount = 0.5 ether;
        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);
        (success,) = payable(clone1).call{value: amount}("");
        assertTrue(success);
        assertEq(clone1.balance, amount);

        (addresses, amounts) = controller.keeperFees(recipients);
        assertTrue(addresses.length == 2);
        assertTrue(addresses[0] == clone0);
        assertTrue(addresses[1] == clone1);
        assertTrue(amounts.length == 2);
        assertTrue(amounts[0] == 0.09 ether);
        assertTrue(amounts[1] == 0.045 ether);

        address[] memory shares = new address[](1);
        shares[0] = clone1;
        (addresses, amounts) = controller.keeperFees(recipients, shares);
        assertTrue(addresses.length == 1);
        assertTrue(addresses[0] == clone1);
        assertTrue(amounts.length == 1);
        assertTrue(amounts[0] == 0.045 ether);
    }

    function testKeeperShares() public {
        address[] memory recipients;

        // add tokenized share 0
        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");
        uint16[] memory clone0Shares = new uint16[](3);
        clone0Shares[0] = 5_000;
        clone0Shares[1] = 3_000;
        clone0Shares[2] = 2_000;
        address clone0 = controller.addTokenizedShares(1_000, recipients, clone0Shares, name, symbol);
        assertEq(clone0.balance, 0);

        (address[] memory addresses, uint256[] memory amounts) = controller.keeperShares();
        assertTrue(addresses.length == 1);
        assertTrue(addresses[0] == clone0);
        assertTrue(amounts.length == 1);
        assertTrue(amounts[0] == 1_000);

        // add tokenized share 1
        uint16[] memory clone1Shares = new uint16[](3);
        clone1Shares[0] = 5_000;
        clone1Shares[1] = 3_000;
        clone1Shares[2] = 2_000;
        address clone1 = controller.addTokenizedShares(500, recipients, clone1Shares, name, symbol);
        assertEq(clone1.balance, 0);

        (addresses, amounts) = controller.keeperShares();
        assertTrue(addresses.length == 2);
        assertTrue(addresses[0] == clone0);
        assertTrue(addresses[1] == clone1);
        assertTrue(amounts.length == 2);
        assertTrue(amounts[0] == 1_000);
        assertTrue(amounts[1] == 500);

        address[] memory shares = new address[](1);
        shares[0] = clone1;
        (addresses, amounts) = controller.keeperShares(shares);
        assertTrue(addresses.length == 1);
        assertTrue(addresses[0] == clone1);
        assertTrue(amounts.length == 1);
        assertTrue(amounts[0] == 500);
    }

    function testReleasable() public {
        address[] memory recipients;

        // add tokenized share 0
        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");
        uint16[] memory clone0Shares = new uint16[](3);
        clone0Shares[0] = 5_000;
        clone0Shares[1] = 3_000;
        clone0Shares[2] = 2_000;
        address clone0 = controller.addTokenizedShares(1_000, recipients, clone0Shares, name, symbol);
        assertEq(clone0.balance, 0);

        (address[] memory addresses, uint256[][] memory amounts) = controller.releasable(recipients);
        assertTrue(addresses.length == 1);
        assertTrue(addresses[0] == clone0);
        assertTrue(amounts.length == 1);
        assertTrue(amounts[0].length == 3);
        assertTrue(amounts[0][0] == 0);
        assertTrue(amounts[0][1] == 0);
        assertTrue(amounts[0][2] == 0);

        // deposit
        uint256 amount = 1 ether;
        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);
        (bool success,) = payable(clone0).call{value: amount}("");
        assertTrue(success);
        assertEq(clone0.balance, amount);

        (addresses, amounts) = controller.releasable(recipients);
        assertTrue(addresses.length == 1);
        assertTrue(addresses[0] == clone0);
        assertTrue(amounts.length == 1);
        assertTrue(amounts[0].length == 3);
        assertTrue(amounts[0][0] == 0.45 ether);
        assertTrue(amounts[0][1] == 0.27 ether);
        assertTrue(amounts[0][2] == 0.18 ether);

        // add tokenized share 1
        uint16[] memory clone1Shares = new uint16[](3);
        clone1Shares[0] = 5_000;
        clone1Shares[1] = 3_000;
        clone1Shares[2] = 2_000;
        address clone1 = controller.addTokenizedShares(500, recipients, clone1Shares, name, symbol);
        assertEq(clone1.balance, 0);

        // deposit
        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);
        (success,) = payable(clone1).call{value: amount}("");
        assertTrue(success);
        assertEq(clone1.balance, amount);

        (addresses, amounts) = controller.releasable(recipients);
        assertTrue(addresses.length == 2);
        assertTrue(addresses[0] == clone0);
        assertTrue(addresses[1] == clone1);
        assertTrue(amounts.length == 2);
        assertTrue(amounts[0].length == 3);
        assertTrue(amounts[0][0] == 0.45 ether);
        assertTrue(amounts[0][1] == 0.27 ether);
        assertTrue(amounts[0][2] == 0.18 ether);
        assertTrue(amounts[1].length == 3);
        assertTrue(amounts[1][0] == 0.475 ether);
        assertTrue(amounts[1][1] == 0.285 ether);
        assertTrue(amounts[1][2] == 0.19 ether);

        address[] memory shares = new address[](1);
        shares[0] = clone1;
        (addresses, amounts) = controller.releasable(recipients, shares);
        assertTrue(addresses.length == 1);
        assertTrue(addresses[0] == clone1);
        assertTrue(amounts.length == 1);
        assertTrue(amounts[0].length == 3);
        assertTrue(amounts[0][0] == 0.475 ether);
        assertTrue(amounts[0][1] == 0.285 ether);
        assertTrue(amounts[0][2] == 0.19 ether);
    }

    function testSharesOwned() public {
        address[] memory recipients;

        // add tokenized share 0
        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");
        uint16[] memory clone0Shares = new uint16[](3);
        clone0Shares[0] = 5_000;
        clone0Shares[1] = 3_000;
        clone0Shares[2] = 2_000;
        address clone0 = controller.addTokenizedShares(1_000, recipients, clone0Shares, name, symbol);
        assertEq(clone0.balance, 0);

        (address[] memory addresses, uint256[][] memory amounts) = controller.sharesOwned(recipients);
        assertTrue(addresses.length == 1);
        assertTrue(addresses[0] == clone0);
        assertTrue(amounts.length == 1);
        assertTrue(amounts[0].length == 3);
        assertTrue(amounts[0][0] == 5_000);
        assertTrue(amounts[0][1] == 3_000);
        assertTrue(amounts[0][2] == 2_000);

        // add tokenized share 1
        uint16[] memory clone1Shares = new uint16[](3);
        clone1Shares[0] = 5_000;
        clone1Shares[1] = 3_000;
        clone1Shares[2] = 2_000;
        address clone1 = controller.addTokenizedShares(500, recipients, clone1Shares, name, symbol);
        assertEq(clone1.balance, 0);

        (addresses, amounts) = controller.sharesOwned(recipients);
        assertTrue(addresses.length == 2);
        assertTrue(addresses[0] == clone0);
        assertTrue(addresses[1] == clone1);
        assertTrue(amounts.length == 2);
        assertTrue(amounts[0].length == 3);
        assertTrue(amounts[0][0] == 5_000);
        assertTrue(amounts[0][1] == 3_000);
        assertTrue(amounts[0][2] == 2_000);
        assertTrue(amounts[1].length == 3);
        assertTrue(amounts[1][0] == 5_000);
        assertTrue(amounts[1][1] == 3_000);
        assertTrue(amounts[1][2] == 2_000);

        address[] memory shares = new address[](1);
        shares[0] = clone1;
        (addresses, amounts) = controller.sharesOwned(recipients, shares);
        assertTrue(addresses.length == 1);
        assertTrue(addresses[0] == clone1);
        assertTrue(amounts.length == 1);
        assertTrue(amounts[0].length == 3);
        assertTrue(amounts[0][0] == 5_000);
        assertTrue(amounts[0][1] == 3_000);
        assertTrue(amounts[0][2] == 2_000);
    }

    function testTokenizedSharesAddresses() public {
        address[] memory tokenizedSharesAddresses;
        address tokenizedShares;
        address[] memory recipients;
        uint16[] memory shares;

        tokenizedSharesAddresses = controller.tokenizedSharesAddresses();
        assertTrue(tokenizedSharesAddresses.length == 0);

        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        shares = new uint16[](3);
        shares[0] = 7_000;
        shares[1] = 2_000;
        shares[2] = 1_000;

        tokenizedShares = controller.addTokenizedShares(0, recipients, shares, name, symbol);
        tokenizedSharesAddresses = controller.tokenizedSharesAddresses();
        assertTrue(tokenizedSharesAddresses.length == 1);

        tokenizedShares = controller.addTokenizedShares(0, recipients, shares, name, symbol);
        tokenizedSharesAddresses = controller.tokenizedSharesAddresses();
        assertTrue(tokenizedSharesAddresses.length == 2);

        tokenizedShares = controller.addTokenizedShares(0, recipients, shares, name, symbol);
        tokenizedSharesAddresses = controller.tokenizedSharesAddresses();
        assertTrue(tokenizedSharesAddresses.length == 3);
    }
}
