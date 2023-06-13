// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SharesFactory.sol";
import "../src/examples/ERC20TokenSharesMock.sol";

contract ERC20TokenSharesTest is Test {
    event ReceiveETH(uint256);
    event NewTokenizedShares(address tokenizedShares);

    SharesFactory public factory;

    function setUp() public {
        factory = new SharesFactory(address(new ERC20TokenSharesMock()));
    }

    function testERC20Decimals() public {
        address tokenizedShares;
        address[] memory recipients;
        uint256[] memory shares;

        // Success
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
        assertEq(ERC20(tokenizedShares).decimals(), 18);
    }

    function testERC20CustomData() public {
        address tokenizedShares;
        uint256[] memory shares;
        address[] memory recipients;

        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        shares = new uint256[](3);
        shares[0] = 7_000;
        shares[1] = 2_000;
        shares[2] = 1_000;

        ERC20TokenSharesMock.Data memory data = ERC20TokenSharesMock.Data({name: "NAME", symbol: "SYMBOL"});
        bytes memory encodedData = abi.encode(data);

        tokenizedShares = factory.addTokenizedShares(recipients, shares, encodedData);
        bytes memory customData = ITokenizedShares(tokenizedShares).customData();
        assertEq(encodedData.length, customData.length);
        assertEq(encodedData, customData);

        ERC20TokenSharesMock.Data memory decodedData = abi.decode(customData, (ERC20TokenSharesMock.Data));
        assertEq(decodedData.name, data.name);
        assertEq(decodedData.symbol, data.symbol);
    }

    function testERC20AddTokenizedShares() public {
        address tokenizedShares;
        address[] memory recipients;
        uint256[] memory shares;

        // Revert ITokenizedShares__NoRecipients
        recipients = new address[](0);
        vm.expectRevert(ITokenizedShares.ITokenizedShares__NoRecipients.selector);
        factory.addTokenizedShares(recipients, shares);

        // Revert ITokenizedShares__ArrayLengthsMismatch
        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        shares = new uint256[](1);
        vm.expectRevert(ITokenizedShares.ITokenizedShares__ArrayLengthsMismatch.selector);
        factory.addTokenizedShares(recipients, shares);

        // Revert ITokenizedShares__InvalidSharesAmount
        shares = new uint256[](3);
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

        uint256 decimals = ERC20(tokenizedShares).decimals();
        assertEq(decimals, 18);

        assertEq(ITokenizedShares(tokenizedShares).factory(), address(factory));
        assertEq(ITokenizedShares(tokenizedShares).keeperShares(), 0);
        assertEq(ERC20(tokenizedShares).balanceOf(recipients[0]), shares[0] * 10 ** decimals);
        assertEq(ERC20(tokenizedShares).balanceOf(recipients[1]), shares[1] * 10 ** decimals);
        assertEq(ERC20(tokenizedShares).balanceOf(recipients[2]), shares[2] * 10 ** decimals);

        // Revert ITokenizedShares__NotSharesFactory
        vm.expectRevert(ITokenizedShares.ITokenizedShares__NotSharesFactory.selector);
        ITokenizedShares(tokenizedShares).factoryMintShares(recipients, shares);
    }

    function testERC20AddTokenizedSharesWithKeeperShares() public {
        address tokenizedShares;
        uint256 keeperShares;
        address[] memory recipients;
        uint256[] memory shares;

        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        // Revert ITokenizedShares__InvalidSharesAmount
        keeperShares = 110;
        shares = new uint256[](3);
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

        uint256 decimals = ERC20(tokenizedShares).decimals();
        assertEq(decimals, 18);

        assertEq(ITokenizedShares(tokenizedShares).factory(), address(factory));
        assertEq(ITokenizedShares(tokenizedShares).keeperShares(), keeperShares * 10 ** decimals);
        assertEq(ERC20(tokenizedShares).balanceOf(recipients[0]), shares[0] * 10 ** decimals);
        assertEq(ERC20(tokenizedShares).balanceOf(recipients[1]), shares[1] * 10 ** decimals);
        assertEq(ERC20(tokenizedShares).balanceOf(recipients[2]), shares[2] * 10 ** decimals);
    }

    function testERC20AddTokenizedSharesWithKeeperSharesithCustomImplementation() public {
        address customImplementation;
        address tokenizedShares;
        uint256 keeperShares;
        address[] memory recipients;
        uint256[] memory shares;

        recipients = new address[](3);
        recipients[0] = makeAddr("recipient_0");
        recipients[1] = makeAddr("recipient_1");
        recipients[2] = makeAddr("recipient_2");

        // Revert ITokenizedShares__InvalidSharesAmount
        keeperShares = 110;
        shares = new uint256[](3);
        shares[0] = 6_889;
        shares[1] = 2_000;
        shares[2] = 1_000;

        vm.expectRevert(ITokenizedShares.ITokenizedShares__InvalidSharesAmount.selector);
        tokenizedShares = factory.addTokenizedShares(keeperShares, recipients, shares);

        // Success
        keeperShares = 111;

        vm.expectEmit(false, false, false, false);
        emit NewTokenizedShares(address(0));

        customImplementation = address(new ERC20TokenSharesMock());
        tokenizedShares = factory.addTokenizedShares(customImplementation, keeperShares, recipients, shares);

        uint256 decimals = ERC20(tokenizedShares).decimals();
        assertEq(decimals, 18);

        assertEq(ITokenizedShares(tokenizedShares).factory(), address(factory));
        assertEq(ITokenizedShares(tokenizedShares).keeperShares(), keeperShares * 10 ** decimals);
        assertEq(ERC20(tokenizedShares).balanceOf(recipients[0]), shares[0] * 10 ** decimals);
        assertEq(ERC20(tokenizedShares).balanceOf(recipients[1]), shares[1] * 10 ** decimals);
        assertEq(ERC20(tokenizedShares).balanceOf(recipients[2]), shares[2] * 10 ** decimals);
    }

    function testERC20MultiAddTokenizedShares() public {
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

            uint256 decimals = ERC20(tokenizedShares).decimals();
            assertEq(decimals, 18);

            assertEq(ITokenizedShares(tokenizedShares).factory(), address(factory));
            assertEq(ITokenizedShares(tokenizedShares).keeperShares(), 0);
            assertEq(ERC20(tokenizedShares).balanceOf(recipients[0]), shares[0] * 10 ** decimals);
            assertEq(ERC20(tokenizedShares).balanceOf(recipients[1]), shares[1] * 10 ** decimals);
            assertEq(ERC20(tokenizedShares).balanceOf(recipients[2]), shares[2] * 10 ** decimals);
        }
    }

    function testERC20MultiAddTokenizedSharesWithKeeperShares() public {
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

            uint256 decimals = ERC20(tokenizedShares).decimals();
            assertEq(decimals, 18);

            assertEq(ITokenizedShares(tokenizedShares).factory(), address(factory));
            assertEq(ITokenizedShares(tokenizedShares).keeperShares(), keeperShares * 10 ** decimals);
            assertEq(ERC20(tokenizedShares).balanceOf(recipients[0]), shares[0] * 10 ** decimals);
            assertEq(ERC20(tokenizedShares).balanceOf(recipients[1]), shares[1] * 10 ** decimals);
            assertEq(ERC20(tokenizedShares).balanceOf(recipients[2]), shares[2] * 10 ** decimals);
        }
    }

    function testERC20Deposit() public {
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

        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);

        (bool success,) = payable(tokenizedShares).call{value: amount}("");

        assertTrue(success);
        assertEq(tokenizedShares.balance, amount);
    }

    function testERC20DepositWithKeeperShares() public {
        uint256 amount = 1 ether;

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

        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);

        (bool success,) = payable(tokenizedShares).call{value: amount}("");

        assertTrue(success);
        assertEq(tokenizedShares.balance, amount);
    }

    function testERC20ReleaseShares() public {
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

    function testERC20ReleaseSharesWithKeeperShares() public {
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

    function testERC20FuzzAddTokenizedShares(uint256 shares1, uint256 shares2) public {
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

        address tokenizedShares = factory.addTokenizedShares(recipients, shares);

        uint256 decimals = ERC20(tokenizedShares).decimals();
        assertEq(decimals, 18);

        assertEq(ITokenizedShares(tokenizedShares).keeperShares(), 0);
        assertEq(ERC20(tokenizedShares).balanceOf(recipients[0]), shares[0] * 10 ** decimals);
        assertEq(ERC20(tokenizedShares).balanceOf(recipients[1]), shares[1] * 10 ** decimals);
        assertEq(ERC20(tokenizedShares).balanceOf(recipients[2]), shares[2] * 10 ** decimals);
    }

    function testERC20FuzzAddTokenizedSharesWithKeeperShares(uint256 keeperShares, uint256 shares1, uint256 shares2)
        public
    {
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

        address tokenizedShares = factory.addTokenizedShares(keeperShares, recipients, shares);

        uint256 decimals = ERC20(tokenizedShares).decimals();
        assertEq(decimals, 18);

        assertEq(ITokenizedShares(tokenizedShares).factory(), address(factory));
        assertEq(ITokenizedShares(tokenizedShares).keeperShares(), keeperShares * 10 ** decimals);
        assertEq(ERC20(tokenizedShares).balanceOf(recipients[0]), shares[0] * 10 ** decimals);
        assertEq(ERC20(tokenizedShares).balanceOf(recipients[1]), shares[1] * 10 ** decimals);
        assertEq(ERC20(tokenizedShares).balanceOf(recipients[2]), shares[2] * 10 ** decimals);
    }

    function testERC20FuzzAddTokenizedSharesWithKeeperSharesWithCustomImplementation(
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

        address customImplementation = address(new ERC20TokenSharesMock());
        address tokenizedShares = factory.addTokenizedShares(customImplementation, keeperShares, recipients, shares);

        uint256 decimals = ERC20(tokenizedShares).decimals();
        assertEq(decimals, 18);

        assertEq(ITokenizedShares(tokenizedShares).factory(), address(factory));
        assertEq(ITokenizedShares(tokenizedShares).keeperShares(), keeperShares * 10 ** decimals);
        assertEq(ERC20(tokenizedShares).balanceOf(recipients[0]), shares[0] * 10 ** decimals);
        assertEq(ERC20(tokenizedShares).balanceOf(recipients[1]), shares[1] * 10 ** decimals);
        assertEq(ERC20(tokenizedShares).balanceOf(recipients[2]), shares[2] * 10 ** decimals);
    }

    function testERC20FuzzMultiAddTokenizedShares(uint256 shares1, uint256 shares2) public {
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

            ERC20 tokenizedShares = ERC20(factory.addTokenizedShares(recipients, shares));

            uint256 decimals = tokenizedShares.decimals();
            assertEq(decimals, 18);

            assertEq(tokenizedShares.balanceOf(recipients[0]), shares[0] * 10 ** decimals);
            assertEq(tokenizedShares.balanceOf(recipients[1]), shares[1] * 10 ** decimals);
            assertEq(tokenizedShares.balanceOf(recipients[2]), shares[2] * 10 ** decimals);
        }
    }

    function testERC20FuzzMultiAddTokenizedSharesWithKeeperShares(
        uint256 keeperShares,
        uint256 shares1,
        uint256 shares2
    ) public {
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

            uint256 decimals = ERC20(tokenizedShares).decimals();
            assertEq(decimals, 18);

            assertEq(ITokenizedShares(tokenizedShares).factory(), address(factory));
            assertEq(ITokenizedShares(tokenizedShares).keeperShares(), keeperShares * 10 ** decimals);
            assertEq(ERC20(tokenizedShares).balanceOf(recipients[0]), shares[0] * 10 ** decimals);
            assertEq(ERC20(tokenizedShares).balanceOf(recipients[1]), shares[1] * 10 ** decimals);
            assertEq(ERC20(tokenizedShares).balanceOf(recipients[2]), shares[2] * 10 ** decimals);
        }
    }

    function testERC20FuzzDeposit(uint256 amount) public {
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

        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);

        (bool success,) = payable(tokenizedShares).call{value: amount}("");

        assertTrue(success);
        assertEq(tokenizedShares.balance, amount);
    }

    function testERC20FuzzDepositWithKeeperShares(uint256 amount) public {
        vm.deal(address(this), amount);

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

        vm.expectEmit(false, false, false, true);
        emit ReceiveETH(amount);

        (bool success,) = payable(tokenizedShares).call{value: amount}("");

        assertTrue(success);
        assertEq(tokenizedShares.balance, amount);
    }

    function testERC20FuzzReleaseShares(uint256 amount) public {
        vm.assume(amount > 0 && amount < 100_000_000 * 1e18);
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

    function testERC20FuzzReleaseSharesWithKeeperShares(uint256 amount) public {
        vm.assume(amount > 0 && amount < 100_000_000 * 1e18);
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
