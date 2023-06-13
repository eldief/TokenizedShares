// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SharesFactory.sol";
import "../src/examples/ERC1155TokenSharesMock.sol";

contract SharesFactoryTest is Test {
    event ReceiveETH(uint256);
    event NewTokenizedShares(address tokenizedShares);

    SharesFactory public factory;

    function setUp() public {
        factory = new SharesFactory(address(new ERC1155TokenSharesMock()));
    }

    function testAddTokenShares() public {
        address tokenizedShares;
        address[] memory recipients;
        uint256[] memory shares;

        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        shares = new uint256[](3);
        shares[0] = 7_000;
        shares[1] = 2_000;
        shares[2] = 1_000;

        vm.expectEmit(false, false, false, false);
        emit NewTokenizedShares(address(0));

        tokenizedShares = factory.addTokenizedShares(recipients, shares);

        assertEq(ITokenizedShares(tokenizedShares).factory(), address(factory));
        assertEq(ITokenizedShares(tokenizedShares).keeperShares(), 0);
        assertEq(ERC1155(tokenizedShares).balanceOf(recipients[0], 0), shares[0]);
        assertEq(ERC1155(tokenizedShares).balanceOf(recipients[1], 0), shares[1]);
        assertEq(ERC1155(tokenizedShares).balanceOf(recipients[2], 0), shares[2]);
    }

    function testAddTokenSharesWithKeeperShares() public {
        address tokenizedShares;
        uint256 keeperShares;
        address[] memory recipients;
        uint256[] memory shares;

        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        shares = new uint256[](3);
        shares[0] = 6_889;
        shares[1] = 2_000;
        shares[2] = 1_000;

        // Revert ISharesFactory__InvalidKeeperShares
        keeperShares = 1001;
        vm.expectRevert(ISharesFactory.ISharesFactory__InvalidKeeperShares.selector);
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

    function testAddTokenSharesWithKeeperSharesWithCustomImplementation() public {
        address customImplementation;
        address tokenizedShares;
        uint256 keeperShares;
        address[] memory recipients;
        uint256[] memory shares;

        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        shares = new uint256[](3);
        shares[0] = 6_889;
        shares[1] = 2_000;
        shares[2] = 1_000;

        // Revert ISharesFactory__InvalidKeeperShares
        keeperShares = 1001;
        vm.expectRevert(ISharesFactory.ISharesFactory__InvalidKeeperShares.selector);
        tokenizedShares = factory.addTokenizedShares(keeperShares, recipients, shares);

        // Success
        customImplementation = address(new ERC1155TokenSharesMock());
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

    function testMultiAddTokenShares() public {
        uint256 number = 10;

        for (uint256 i = 1; i <= number; ++i) {
            address[] memory recipients = new address[](3);
            recipients[0] = makeAddr(string(abi.encode(i)));
            recipients[1] = makeAddr(string(abi.encode(i + i)));
            recipients[2] = makeAddr(string(abi.encode(i + i + i)));

            uint256[] memory shares = new uint256[](3);
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

    function testMultiAddTokenSharesWithKeeperShares() public {
        uint256 number = 10;

        for (uint256 i = 1; i <= number; ++i) {
            address[] memory recipients = new address[](3);
            recipients[0] = makeAddr(string(abi.encode(i)));
            recipients[1] = makeAddr(string(abi.encode(i + i)));
            recipients[2] = makeAddr(string(abi.encode(i + i + i)));

            uint256 keeperShares = 111;
            uint256[] memory shares = new uint256[](3);
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

    function testReleaseShares() public {
        // Revert ISharesFactory.ISharesFactory__NoTokenShares
        vm.expectRevert(ISharesFactory.ISharesFactory__NoTokenShares.selector);
        factory.releaseShares(new address[](1));

        // Success
        uint256 amount = 1 ether;

        address[] memory recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        uint256[] memory shares = new uint256[](3);
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

    function testReleaseSharesWithKeeperShares() public {
        // Revert ISharesFactory.ISharesFactory__NoTokenShares
        vm.expectRevert(ISharesFactory.ISharesFactory__NoTokenShares.selector);
        factory.releaseShares(new address[](1));

        // Success
        uint256 amount = 1 ether;

        address keeper = makeAddr("keeper");
        address[] memory recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        uint256 keeperShares = 111;
        uint256[] memory shares = new uint256[](3);
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

    //--------------------------------------//
    //                FUZZ                  //
    //--------------------------------------//

    function testFuzzAddTokenShares(uint256 shares1, uint256 shares2) public {
        vm.assume(shares1 > 0 && shares1 < 10_000);
        vm.assume(shares2 > 0 && shares2 < 10_000);
        vm.assume(shares1 + shares2 < 10_000);
        uint256 shares3 = 10_000 - shares1 - shares2;

        address[] memory recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        uint256[] memory shares = new uint256[](3);
        shares[0] = shares1;
        shares[1] = shares2;
        shares[2] = shares3;

        ERC1155 tokenizedShares = ERC1155(factory.addTokenizedShares(recipients, shares));
        assertEq(tokenizedShares.balanceOf(recipients[0], 0), shares[0]);
        assertEq(tokenizedShares.balanceOf(recipients[1], 0), shares[1]);
        assertEq(tokenizedShares.balanceOf(recipients[2], 0), shares[2]);
    }

    function testFuzzAddTokenSharesWithKeeperShares(uint256 keeperShares, uint256 shares1, uint256 shares2) public {
        vm.assume(keeperShares > 0 && keeperShares <= 1_000);
        vm.assume(shares1 > 0 && shares1 < 10_000);
        vm.assume(shares2 > 0 && shares2 < 10_000);
        vm.assume(shares1 + shares2 + keeperShares < 10_000);
        uint256 shares3 = 10_000 - shares1 - shares2 - keeperShares;

        address[] memory recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        uint256[] memory shares = new uint256[](3);
        shares[0] = shares1;
        shares[1] = shares2;
        shares[2] = shares3;

        ERC1155 tokenizedShares = ERC1155(factory.addTokenizedShares(keeperShares, recipients, shares));
        assertEq(tokenizedShares.balanceOf(recipients[0], 0), shares[0]);
        assertEq(tokenizedShares.balanceOf(recipients[1], 0), shares[1]);
        assertEq(tokenizedShares.balanceOf(recipients[2], 0), shares[2]);
    }

    function testFuzzAddTokenSharesWithKeeperSharesWithCustomImplementation(
        uint256 keeperShares,
        uint256 shares1,
        uint256 shares2
    ) public {
        vm.assume(keeperShares > 0 && keeperShares <= 1_000);
        vm.assume(shares1 > 0 && shares1 < 10_000);
        vm.assume(shares2 > 0 && shares2 < 10_000);
        vm.assume(shares1 + shares2 + keeperShares < 10_000);
        uint256 shares3 = 10_000 - shares1 - shares2 - keeperShares;

        address[] memory recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        uint256[] memory shares = new uint256[](3);
        shares[0] = shares1;
        shares[1] = shares2;
        shares[2] = shares3;

        address customImplementation = address(new ERC1155TokenSharesMock());
        ERC1155 tokenizedShares =
            ERC1155(factory.addTokenizedShares(customImplementation, keeperShares, recipients, shares));
        assertEq(tokenizedShares.balanceOf(recipients[0], 0), shares[0]);
        assertEq(tokenizedShares.balanceOf(recipients[1], 0), shares[1]);
        assertEq(tokenizedShares.balanceOf(recipients[2], 0), shares[2]);
    }

    function testFuzzMultiAddTokenShares(uint256 shares1, uint256 shares2) public {
        vm.assume(shares1 > 0 && shares1 < 10_000);
        vm.assume(shares2 > 0 && shares2 < 10_000);
        vm.assume(shares1 + shares2 < 10_000);

        uint256 shares3 = 10_000 - shares1 - shares2;
        uint256 number = 10;
        vm.assume(shares3 > number);

        for (uint256 i = 1; i <= number; ++i) {
            address[] memory recipients = new address[](3);
            recipients[0] = makeAddr(string(abi.encode(i)));
            recipients[1] = makeAddr(string(abi.encode(i + i)));
            recipients[2] = makeAddr(string(abi.encode(i + i + i)));

            uint256[] memory shares = new uint256[](3);
            shares[0] = shares1;
            shares[1] = shares2 + i;
            shares[2] = shares3 - i;

            ERC1155 tokenizedShares = ERC1155(factory.addTokenizedShares(recipients, shares));
            assertEq(tokenizedShares.balanceOf(recipients[0], 0), shares[0]);
            assertEq(tokenizedShares.balanceOf(recipients[1], 0), shares[1]);
            assertEq(tokenizedShares.balanceOf(recipients[2], 0), shares[2]);
        }
    }

    function testFuzzMultiAddTokenSharesWithKeeperShares(uint256 keeperShares, uint256 shares1, uint256 shares2)
        public
    {
        vm.assume(keeperShares > 0 && keeperShares <= 1_000);
        vm.assume(shares1 > 0 && shares1 < 10_000);
        vm.assume(shares2 > 0 && shares2 < 10_000);
        vm.assume(shares1 + shares2 + keeperShares < 10_000);

        uint256 shares3 = 10_000 - shares1 - shares2 - keeperShares;
        uint256 number = 10;
        vm.assume(shares3 > number);

        for (uint256 i = 1; i <= number; ++i) {
            address[] memory recipients = new address[](3);
            recipients[0] = makeAddr(string(abi.encode(i)));
            recipients[1] = makeAddr(string(abi.encode(i + i)));
            recipients[2] = makeAddr(string(abi.encode(i + i + i)));

            uint256[] memory shares = new uint256[](3);
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

    function testFuzzReleaseShares(uint256 amount) public {
        vm.assume(amount > 0 && amount < UINT256_MAX / 10_000);
        vm.deal(address(this), amount);

        address[] memory recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        uint256[] memory shares = new uint256[](3);
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

    function testFuzzReleaseSharesWithKeeperShares(uint256 amount) public {
        vm.assume(amount > 0 && amount < UINT256_MAX / 10_000);
        vm.deal(address(this), amount);

        address keeper = makeAddr("keeper");
        address[] memory recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        uint256 keeperShares = 111;
        uint256[] memory shares = new uint256[](3);
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
