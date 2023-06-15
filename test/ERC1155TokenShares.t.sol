// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SharesFactory.sol";
import "../src/examples/ERC1155TokenizedSharesMock.sol";

contract ERC1155TokenSharesTest is Test {
    event ReceiveETH(uint256);
    event NewTokenizedShares(address tokenizedShares);

    SharesFactory public factory;

    function setUp() public {
        factory = new SharesFactory(address(new ERC1155TokenizedSharesMock()));
    }

    function testERC1155AddTokenizedShares() public {
        address tokenizedShares;
        address[] memory recipients;
        uint16[] memory shares;

        // Revert ITokenizedShares__NoRecipients
        recipients = new address[](0);
        vm.expectRevert(ITokenizedShares.ITokenizedShares__NoRecipients.selector);
        factory.addTokenizedShares(recipients, shares);

        // Revert ITokenizedShares__ArrayLengthsMismatch
        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        shares = new uint16[](1);
        vm.expectRevert(ITokenizedShares.ITokenizedShares__ArrayLengthsMismatch.selector);
        factory.addTokenizedShares(recipients, shares);

        // Revert ITokenizedShares__InvalidSharesAmount
        shares = new uint16[](3);
        shares[0] = 6_999;
        shares[1] = 2_000;
        shares[2] = 1_000;

        vm.expectRevert(ITokenizedShares.ITokenizedShares__InvalidSharesAmount.selector);
        tokenizedShares = factory.addTokenizedShares(recipients, shares);

        // Success
        shares[0] = 7_000;

        vm.expectEmit(false, false, false, false);
        emit NewTokenizedShares(address(0));

        tokenizedShares = factory.addTokenizedShares(recipients, shares);

        assertEq(ITokenizedShares(tokenizedShares).factory(), address(factory));
        assertEq(ITokenizedShares(tokenizedShares).keeperShares(), 0);
        assertEq(ERC1155(tokenizedShares).balanceOf(recipients[0], 0), shares[0]);
        assertEq(ERC1155(tokenizedShares).balanceOf(recipients[1], 0), shares[1]);
        assertEq(ERC1155(tokenizedShares).balanceOf(recipients[2], 0), shares[2]);

        // Revert ITokenizedShares__NotSharesFactory
        vm.expectRevert(ITokenizedShares.ITokenizedShares__NotSharesFactory.selector);
        ITokenizedShares(tokenizedShares).factoryMintShares(recipients, shares);
    }

    function testERC1155AddTokenizedSharesWithKeeperShares() public {
        address tokenizedShares;
        uint16 keeperShares;
        address[] memory recipients;
        uint16[] memory shares;

        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        // Revert ITokenizedShares__InvalidSharesAmount
        keeperShares = 110;
        shares = new uint16[](3);
        shares[0] = 6_889;
        shares[1] = 2_000;
        shares[2] = 1_000;

        vm.expectRevert(ITokenizedShares.ITokenizedShares__InvalidSharesAmount.selector);
        tokenizedShares = factory.addTokenizedShares(keeperShares, recipients, shares);

        // Success
        keeperShares = 111;

        vm.expectEmit(false, false, false, false);
        emit NewTokenizedShares(address(0));

        tokenizedShares = factory.addTokenizedShares(keeperShares, recipients, shares);

        assertEq(ITokenizedShares(tokenizedShares).factory(), address(factory));
        assertEq(ITokenizedShares(tokenizedShares).keeperShares(), keeperShares);
        assertEq(ERC1155(tokenizedShares).balanceOf(recipients[0], 0), shares[0]);
        assertEq(ERC1155(tokenizedShares).balanceOf(recipients[1], 0), shares[1]);
        assertEq(ERC1155(tokenizedShares).balanceOf(recipients[2], 0), shares[2]);
    }

    function testERC1155AddTokenizedSharesWithKeeperSharesWithCustomImplementation() public {
        address customImplementation;
        address tokenizedShares;
        uint16 keeperShares;
        address[] memory recipients;
        uint16[] memory shares;

        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        // Revert ITokenizedShares__InvalidSharesAmount
        keeperShares = 110;
        shares = new uint16[](3);
        shares[0] = 6_889;
        shares[1] = 2_000;
        shares[2] = 1_000;

        vm.expectRevert(ITokenizedShares.ITokenizedShares__InvalidSharesAmount.selector);
        tokenizedShares = factory.addTokenizedShares(keeperShares, recipients, shares);

        // Success
        customImplementation = address(new ERC1155TokenizedSharesMock());
        keeperShares = 111;

        vm.expectEmit(false, false, false, false);
        emit NewTokenizedShares(address(0));

        tokenizedShares = factory.addTokenizedShares(customImplementation, keeperShares, recipients, shares);

        assertEq(ITokenizedShares(tokenizedShares).factory(), address(factory));
        assertEq(ITokenizedShares(tokenizedShares).keeperShares(), keeperShares);
        assertEq(ERC1155(tokenizedShares).balanceOf(recipients[0], 0), shares[0]);
        assertEq(ERC1155(tokenizedShares).balanceOf(recipients[1], 0), shares[1]);
        assertEq(ERC1155(tokenizedShares).balanceOf(recipients[2], 0), shares[2]);
    }

    function testERC1155MultiAddTokenizedShares() public {
        uint256 number = 10;

        for (uint16 i = 1; i <= number; ++i) {
            address[] memory recipients = new address[](3);
            recipients[0] = makeAddr(string(abi.encode(i)));
            recipients[1] = makeAddr(string(abi.encode(i + i)));
            recipients[2] = makeAddr(string(abi.encode(i + i + i)));

            uint16[] memory shares = new uint16[](3);
            shares[0] = 7_000;
            shares[1] = 2_000 + i;
            shares[2] = 1_000 - i;

            vm.expectEmit(false, false, false, false);
            emit NewTokenizedShares(address(0));

            address tokenizedShares = factory.addTokenizedShares(0, recipients, shares);

            assertEq(ITokenizedShares(tokenizedShares).factory(), address(factory));
            assertEq(ITokenizedShares(tokenizedShares).keeperShares(), 0);
            assertEq(ERC1155(tokenizedShares).balanceOf(recipients[0], 0), shares[0]);
            assertEq(ERC1155(tokenizedShares).balanceOf(recipients[1], 0), shares[1]);
            assertEq(ERC1155(tokenizedShares).balanceOf(recipients[2], 0), shares[2]);
        }
    }

    function testERC1155MultiAddTokenizedSharesWithKeeperShares() public {
        uint16 number = 10;

        for (uint16 i = 1; i <= number; ++i) {
            address[] memory recipients = new address[](3);
            recipients[0] = makeAddr(string(abi.encode(i)));
            recipients[1] = makeAddr(string(abi.encode(i + i)));
            recipients[2] = makeAddr(string(abi.encode(i + i + i)));

            uint16 keeperShares = 111;
            uint16[] memory shares = new uint16[](3);
            shares[0] = 6_889;
            shares[1] = 2_000 + i;
            shares[2] = 1_000 - i;

            vm.expectEmit(false, false, false, false);
            emit NewTokenizedShares(address(0));

            address tokenizedShares = factory.addTokenizedShares(keeperShares, recipients, shares);

            assertEq(ITokenizedShares(tokenizedShares).factory(), address(factory));
            assertEq(ITokenizedShares(tokenizedShares).keeperShares(), keeperShares);
            assertEq(ERC1155(tokenizedShares).balanceOf(recipients[0], 0), shares[0]);
            assertEq(ERC1155(tokenizedShares).balanceOf(recipients[1], 0), shares[1]);
            assertEq(ERC1155(tokenizedShares).balanceOf(recipients[2], 0), shares[2]);
        }
    }

    function testERC1155Deposit() public {
        uint256 amount = 1 ether;

        address[] memory recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        uint16[] memory shares = new uint16[](3);
        shares[0] = 7_000;
        shares[1] = 2_000;
        shares[2] = 1_000;

        address tokenizedShares = factory.addTokenizedShares(recipients, shares);

        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);

        (bool success,) = payable(tokenizedShares).call{value: amount}("");

        assertTrue(success);
        assertEq(tokenizedShares.balance, amount);
    }

    function testERC1155DepositWithKeeperShares() public {
        uint256 amount = 1 ether;

        address[] memory recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        uint16 keeperShares = 111;
        uint16[] memory shares = new uint16[](3);
        shares[0] = 6_889;
        shares[1] = 2_000;
        shares[2] = 1_000;

        address tokenizedShares = factory.addTokenizedShares(keeperShares, recipients, shares);

        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);

        (bool success,) = payable(tokenizedShares).call{value: amount}("");

        assertTrue(success);
        assertEq(tokenizedShares.balance, amount);
    }

    function testERC1155ReleaseShares() public {
        // Success
        uint256 amount = 1 ether;

        address[] memory recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        uint16[] memory shares = new uint16[](3);
        shares[0] = 7_000;
        shares[1] = 2_000;
        shares[2] = 1_000;

        address tokenizedShares = factory.addTokenizedShares(recipients, shares);
        (bool success,) = payable(tokenizedShares).call{value: amount}("");
        assertTrue(success);

        address[] memory owners = new address[](1);
        owners[0] = recipients[0];

        factory.releaseShares(owners);

        assertEq(recipients[0].balance, amount * shares[0] / 10_000);

        owners = new address[](2);
        owners[0] = recipients[1];
        owners[1] = recipients[2];

        factory.releaseShares(owners);

        assertEq(recipients[1].balance, amount * shares[1] / 10_000);
        assertEq(recipients[2].balance, amount * shares[2] / 10_000);
    }

    function testERC1155ReleaseSharesWithTransfer() public {
        // Success
        uint256 amount = 1 ether;

        address[] memory recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        uint16[] memory shares = new uint16[](3);
        shares[0] = 7_000;
        shares[1] = 2_000;
        shares[2] = 1_000;

        address tokenizedShares = factory.addTokenizedShares(recipients, shares);
        (bool success,) = payable(tokenizedShares).call{value: amount}("");
        assertTrue(success);

        // release 7000 shares
        address[] memory owners = new address[](1);
        owners[0] = recipients[0];
        factory.releaseShares(owners);
        assertEq(owners[0].balance, amount * shares[0] / 10_000);
        uint256 prevBalance = owners[0].balance;

        // release again 7000 shares for same owner, should not increase balance
        factory.releaseShares(owners);
        assertEq(prevBalance, owners[0].balance);

        // transfer 5000/7000 shares to new owner
        address recipient3 = makeAddr("recipient_3");
        vm.prank(owners[0], owners[0]);
        ERC1155(tokenizedShares).safeTransferFrom(owners[0], recipient3, 0, 5_000, "");

        // release 5000 shares to new owner, should not increase balance
        owners[0] = recipient3;
        prevBalance = owners[0].balance;
        factory.releaseShares(owners);
        assertEq(owners[0].balance, 0);

        // release 2000, 1000 shares
        owners = new address[](2);
        owners[0] = recipients[1];
        owners[1] = recipients[2];
        factory.releaseShares(owners);
        assertEq(recipients[1].balance, amount * shares[1] / 10_000);
        assertEq(recipients[2].balance, amount * shares[2] / 10_000);

        // deposit again
        (success,) = payable(tokenizedShares).call{value: amount}("");
        assertTrue(success);

        // release to 5000 shares
        owners = new address[](1);
        owners[0] = recipient3;
        prevBalance = owners[0].balance;
        factory.releaseShares(owners);
        assertEq(owners[0].balance, amount * 5_000 / 10_000);
    }

    function testERC1155ReleaseSharesWithKeeperShares() public {
        uint256 amount = 1 ether;

        address keeper = makeAddr("keeper");
        address[] memory recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        uint16 keeperShares = 111;
        uint16[] memory shares = new uint16[](3);
        shares[0] = 6_889;
        shares[1] = 2_000;
        shares[2] = 1_000;

        address tokenizedShares = factory.addTokenizedShares(keeperShares, recipients, shares);

        (bool success,) = payable(tokenizedShares).call{value: amount}("");
        assertTrue(success);

        address[] memory owners = new address[](1);
        owners[0] = recipients[0];

        uint256 keeperAmount;
        vm.prank(keeper, keeper);
        factory.releaseShares(owners);

        assertEq(recipients[0].balance, amount * shares[0] / 10_000);
        keeperAmount = recipients[0].balance * keeperShares / 10_000;
        assertEq(keeper.balance, keeperAmount);

        owners = new address[](2);
        owners[0] = recipients[1];
        owners[1] = recipients[2];

        vm.prank(keeper, keeper);
        factory.releaseShares(owners);

        assertEq(recipients[1].balance, amount * shares[1] / 10_000);
        assertEq(recipients[2].balance, amount * shares[2] / 10_000);
        keeperAmount = keeperAmount + (recipients[1].balance + recipients[2].balance) * keeperShares / 10_000;
        assertEq(keeper.balance, keeperAmount);
    }

    function testERC1155Releasable() public {
        uint256 amount = 1 ether;

        address[] memory recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        uint16[] memory shares = new uint16[](3);
        shares[0] = 7_000;
        shares[1] = 2_000;
        shares[2] = 1_000;

        // Clone
        address tokenizedShares = factory.addTokenizedShares(recipients, shares);

        // Deposit
        (bool success,) = payable(tokenizedShares).call{value: amount}("");

        assertTrue(success);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[0]), amount * shares[0] / 10_000);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[1]), amount * shares[1] / 10_000);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[2]), amount * shares[2] / 10_000);

        // Release
        factory.releaseShares(recipients);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[0]), 0);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[1]), 0);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[2]), 0);

        // Deposit
        (success,) = payable(tokenizedShares).call{value: amount}("");
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[0]), amount * shares[0] / 10_000);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[1]), amount * shares[1] / 10_000);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[2]), amount * shares[2] / 10_000);

        // Release
        factory.releaseShares(recipients);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[0]), 0);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[1]), 0);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[2]), 0);
    }

    function testERC1155ReleasableWithTransfers() public {
        uint256 amount = 1 ether;

        address[] memory recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        uint16[] memory shares = new uint16[](3);
        shares[0] = 7_000;
        shares[1] = 2_000;
        shares[2] = 1_000;

        // Clone
        address tokenizedShares = factory.addTokenizedShares(recipients, shares);

        // Deposit
        (bool success,) = payable(tokenizedShares).call{value: amount}("");
        assertTrue(success);

        recipients = new address[](4);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");
        recipients[3] = makeAddr("recipient_3");

        // Transfer
        uint256 transferAmount = 5_000;
        vm.prank(recipients[0], recipients[0]);
        ERC1155(tokenizedShares).safeTransferFrom(recipients[0], recipients[3], 0, transferAmount, "");

        assertEq(
            ITokenizedShares(tokenizedShares).releasable(recipients[0]), amount * (shares[0] - transferAmount) / 10_000
        );
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[1]), amount * shares[1] / 10_000);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[2]), amount * shares[2] / 10_000);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[3]), amount * transferAmount / 10_000);

        // Release
        factory.releaseShares(recipients);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[0]), 0);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[1]), 0);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[2]), 0);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[3]), 0);

        // Deposit
        (success,) = payable(tokenizedShares).call{value: amount}("");
        assertTrue(success);
        assertEq(
            ITokenizedShares(tokenizedShares).releasable(recipients[0]), amount * (shares[0] - transferAmount) / 10_000
        );
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[1]), amount * shares[1] / 10_000);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[2]), amount * shares[2] / 10_000);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[3]), amount * transferAmount / 10_000);

        // Release
        factory.releaseShares(recipients);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[0]), 0);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[1]), 0);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[2]), 0);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipients[3]), 0);
    }

    function testERC1155ReleasableWithTransfersAfterRelease() public {
        uint256 amount = 0.001 ether;
        address[] memory recipients;
        uint16[] memory shares;
        bool success;

        address recipient_0 = makeAddr("recipient_0");
        address recipient_1 = makeAddr("recipient_1");
        address recipient_2 = makeAddr("recipient_2");
        address recipient_3 = makeAddr("recipient_3");

        // Distribute shares to 3 recipients
        recipients = new address[](3);
        recipients[0] = recipient_0;
        recipients[1] = recipient_1;
        recipients[2] = recipient_2;

        shares = new uint16[](3);
        shares[0] = 7_000;
        shares[1] = 2_000;
        shares[2] = 1_000;

        address tokenizedShares = factory.addTokenizedShares(recipients, shares);

        // Start accruing shares: 3 x Deposit 0.001 ether
        (success,) = payable(tokenizedShares).call{value: amount}("");
        assertTrue(success);
        (success,) = payable(tokenizedShares).call{value: amount}("");
        assertTrue(success);
        (success,) = payable(tokenizedShares).call{value: amount}("");
        assertTrue(success);

        assertEq(ITokenizedShares(tokenizedShares).releasable(recipient_0), 0.0007 ether * 3);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipient_1), 0.0002 ether * 3);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipient_2), 0.0001 ether * 3);

        // Release shares only on last 2 recipients
        recipients = new address[](2);
        recipients[0] = recipient_1;
        recipients[1] = recipient_2;

        factory.releaseShares(recipients);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipient_0), 0.0007 ether * 3);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipient_1), 0);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipient_2), 0);

        // Transfer 5000 out of 7000 shares from recipient_0 to recipient_3
        vm.prank(recipient_0, recipient_0);
        ERC1155(tokenizedShares).safeTransferFrom(recipient_0, recipient_3, 0, 5000, "");

        assertEq(ITokenizedShares(tokenizedShares).releasable(recipient_0), 0.0002 ether * 3);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipient_1), 0);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipient_2), 0);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipient_3), 0.0005 ether * 3);

        // Start accruing shares: 1 x Deposit 0.001 ether
        (success,) = payable(tokenizedShares).call{value: amount}("");
        assertTrue(success);

        assertEq(ITokenizedShares(tokenizedShares).releasable(recipient_0), 0.0002 ether * 4);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipient_1), 0.0002 ether * 1);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipient_2), 0.0001 ether * 1);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipient_3), 0.0005 ether * 4);

        // Release shares to all recipients
        recipients = new address[](4);
        recipients[0] = recipient_0;
        recipients[1] = recipient_1;
        recipients[2] = recipient_2;
        recipients[3] = recipient_3;

        factory.releaseShares(recipients);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipient_0), 0);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipient_1), 0);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipient_2), 0);
        assertEq(ITokenizedShares(tokenizedShares).releasable(recipient_3), 0);
    }

    //--------------------------------------//
    //                FUZZ                  //
    //--------------------------------------//

    function testERC1155FuzzAddTokenizedShares(uint16 shares1, uint16 shares2) public {
        vm.assume(shares1 > 0 && shares1 < 10_000);
        vm.assume(shares2 > 0 && shares2 < 10_000);
        vm.assume(shares1 + shares2 < 10_000);

        uint16 shares3 = 10_000 - shares1 - shares2;

        address[] memory recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        uint16[] memory shares = new uint16[](3);
        shares[0] = shares1;
        shares[1] = shares2;
        shares[2] = shares3;

        ERC1155 tokenizedShares = ERC1155(factory.addTokenizedShares(recipients, shares));

        assertEq(tokenizedShares.balanceOf(recipients[0], 0), shares[0]);
        assertEq(tokenizedShares.balanceOf(recipients[1], 0), shares[1]);
        assertEq(tokenizedShares.balanceOf(recipients[2], 0), shares[2]);
    }

    function testERC1155FuzzAddTokenizedSharesWithKeeperShares(uint16 keeperShares, uint16 shares1, uint16 shares2)
        public
    {
        vm.assume(keeperShares > 0 && keeperShares <= 1_000);
        vm.assume(shares1 > 0 && shares1 < 10_000);
        vm.assume(shares2 > 0 && shares2 < 10_000);
        vm.assume(shares1 + shares2 + keeperShares < 10_000);

        uint16 shares3 = 10_000 - shares1 - shares2 - keeperShares;

        address[] memory recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        uint16[] memory shares = new uint16[](3);
        shares[0] = shares1;
        shares[1] = shares2;
        shares[2] = shares3;

        ERC1155 tokenizedShares = ERC1155(factory.addTokenizedShares(keeperShares, recipients, shares));

        assertEq(tokenizedShares.balanceOf(recipients[0], 0), shares[0]);
        assertEq(tokenizedShares.balanceOf(recipients[1], 0), shares[1]);
        assertEq(tokenizedShares.balanceOf(recipients[2], 0), shares[2]);
    }

    function testERC1155FuzzAddTokenizedSharesWithKeeperSharesWithCustomImplementation(
        uint16 keeperShares,
        uint16 shares1,
        uint16 shares2
    ) public {
        vm.assume(keeperShares > 0 && keeperShares <= 1_000);
        vm.assume(shares1 > 0 && shares1 < 10_000);
        vm.assume(shares2 > 0 && shares2 < 10_000);
        vm.assume(shares1 + shares2 + keeperShares < 10_000);

        uint16 shares3 = 10_000 - shares1 - shares2 - keeperShares;
        address[] memory recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        uint16[] memory shares = new uint16[](3);
        shares[0] = shares1;
        shares[1] = shares2;
        shares[2] = shares3;

        address customImplementation = address(new ERC1155TokenizedSharesMock());
        ERC1155 tokenizedShares =
            ERC1155(factory.addTokenizedShares(customImplementation, keeperShares, recipients, shares));

        assertEq(tokenizedShares.balanceOf(recipients[0], 0), shares[0]);
        assertEq(tokenizedShares.balanceOf(recipients[1], 0), shares[1]);
        assertEq(tokenizedShares.balanceOf(recipients[2], 0), shares[2]);
    }

    function testERC1155FuzzMultiAddTokenizedShares(uint16 shares1, uint16 shares2) public {
        vm.assume(shares1 > 0 && shares1 < 10_000);
        vm.assume(shares2 > 0 && shares2 < 10_000);
        vm.assume(shares1 + shares2 < 10_000);

        uint16 shares3 = 10_000 - shares1 - shares2;
        uint256 number = 10;
        vm.assume(shares3 > number);

        for (uint16 i = 1; i <= number; ++i) {
            address[] memory recipients = new address[](3);
            recipients[0] = makeAddr(string(abi.encode(i)));
            recipients[1] = makeAddr(string(abi.encode(i + i)));
            recipients[2] = makeAddr(string(abi.encode(i + i + i)));

            uint16[] memory shares = new uint16[](3);
            shares[0] = shares1;
            shares[1] = shares2 + i;
            shares[2] = shares3 - i;

            ERC1155 tokenizedShares = ERC1155(factory.addTokenizedShares(recipients, shares));

            assertEq(tokenizedShares.balanceOf(recipients[0], 0), shares[0]);
            assertEq(tokenizedShares.balanceOf(recipients[1], 0), shares[1]);
            assertEq(tokenizedShares.balanceOf(recipients[2], 0), shares[2]);
        }
    }

    function testERC1155FuzzMultiAddTokenizedSharesWithKeeperShares(uint16 keeperShares, uint16 shares1, uint16 shares2)
        public
    {
        vm.assume(keeperShares > 0 && keeperShares <= 1_000);
        vm.assume(shares1 > 0 && shares1 < 10_000);
        vm.assume(shares2 > 0 && shares2 < 10_000);
        vm.assume(shares1 + shares2 + keeperShares < 10_000);

        uint16 shares3 = 10_000 - shares1 - shares2 - keeperShares;
        uint256 number = 10;
        vm.assume(shares3 > number);

        for (uint16 i = 1; i <= number; ++i) {
            address[] memory recipients = new address[](3);
            recipients[0] = makeAddr(string(abi.encode(i)));
            recipients[1] = makeAddr(string(abi.encode(i + i)));
            recipients[2] = makeAddr(string(abi.encode(i + i + i)));

            uint16[] memory shares = new uint16[](3);
            shares[0] = shares1;
            shares[1] = shares2 + i;
            shares[2] = shares3 - i;

            address tokenizedShares = factory.addTokenizedShares(keeperShares, recipients, shares);
            assertEq(ITokenizedShares(tokenizedShares).factory(), address(factory));
            assertEq(ITokenizedShares(tokenizedShares).keeperShares(), keeperShares);
            assertEq(ERC1155(tokenizedShares).balanceOf(recipients[0], 0), shares[0]);
            assertEq(ERC1155(tokenizedShares).balanceOf(recipients[1], 0), shares[1]);
            assertEq(ERC1155(tokenizedShares).balanceOf(recipients[2], 0), shares[2]);
        }
    }

    function testERC1155FuzzDeposit(uint256 amount) public {
        vm.deal(address(this), amount);

        address[] memory recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        uint16[] memory shares = new uint16[](3);
        shares[0] = 7_000;
        shares[1] = 2_000;
        shares[2] = 1_000;

        address tokenizedShares = factory.addTokenizedShares(recipients, shares);

        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);

        (bool success,) = payable(tokenizedShares).call{value: amount}("");

        assertTrue(success);
        assertEq(tokenizedShares.balance, amount);
    }

    function testERC1155FuzzDepositWithKeeperShares(uint256 amount) public {
        vm.deal(address(this), amount);

        address[] memory recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        uint16 keeperShares = 111;
        uint16[] memory shares = new uint16[](3);
        shares[0] = 6_889;
        shares[1] = 2_000;
        shares[2] = 1_000;

        address tokenizedShares = factory.addTokenizedShares(keeperShares, recipients, shares);

        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);

        (bool success,) = payable(tokenizedShares).call{value: amount}("");

        assertTrue(success);
        assertEq(tokenizedShares.balance, amount);
    }

    function testERC1155FuzzReleaseShares(uint256 amount) public {
        vm.assume(amount > 0 && amount < 100_000_000 * 1e18);
        vm.deal(address(this), amount);

        address[] memory recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        uint16[] memory shares = new uint16[](3);
        shares[0] = 7_000;
        shares[1] = 2_000;
        shares[2] = 1_000;

        address tokenizedShares = factory.addTokenizedShares(recipients, shares);

        (bool success,) = payable(tokenizedShares).call{value: amount}("");
        assertTrue(success);

        factory.releaseShares(recipients);

        assertEq(recipients[0].balance, amount * shares[0] / 10_000);
        assertEq(recipients[1].balance, amount * shares[1] / 10_000);
        assertEq(recipients[2].balance, amount * shares[2] / 10_000);
    }

    function testERC1155FuzzReleaseSharesWithKeeperShares(uint256 amount) public {
        vm.assume(amount > 0 && amount < 100_000_000 * 1e18);
        vm.deal(address(this), amount);

        address keeper = makeAddr("keeper");
        address[] memory recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        uint16 keeperShares = 111;
        uint16[] memory shares = new uint16[](3);
        shares[0] = 6_889;
        shares[1] = 2_000;
        shares[2] = 1_000;

        address tokenizedShares = factory.addTokenizedShares(keeperShares, recipients, shares);

        (bool success,) = payable(tokenizedShares).call{value: amount}("");
        assertTrue(success);

        vm.prank(keeper, keeper);
        factory.releaseShares(recipients);

        assertEq(recipients[0].balance, amount * shares[0] / 10_000);
        assertEq(recipients[1].balance, amount * shares[1] / 10_000);
        assertEq(recipients[2].balance, amount * shares[2] / 10_000);
        assertEq(
            keeper.balance,
            (recipients[0].balance + recipients[1].balance + recipients[2].balance) * keeperShares / 10_000
        );
    }
}
