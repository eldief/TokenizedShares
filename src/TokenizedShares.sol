// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC165} from "./interfaces/IERC165.sol";
import {IERC1155Receiver} from "./interfaces/IERC1155Receiver.sol";
import {ITokenizedShares} from "./interfaces/ITokenizedShares.sol";
import {ITokenizedSharesRenderer} from "./interfaces/ITokenizedSharesRenderer.sol";
import {TokenizedSharesStorage} from "./libraries/TokenizedSharesStorage.sol";
import {TokenizedSharesController} from "./TokenizedSharesController.sol";
import {Clone} from "solady/utils/Clone.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {ERC1155} from "solady/tokens/ERC1155.sol";

/**
 * @title ERC1155TokenizedShares.
 * @author @eldief
 * @notice ERC1155 defining Tokenized Shares functionalities.
 *
 * @dev Immutable args offsets:
 *      0                 20              22           54             86           86 + nameLength     86 + nameLength + symbolLength
 *      | controller addr | keeperShares | nameLength | symbolLength |    name    |       symbol      |
 */
contract TokenizedShares is ITokenizedShares, IERC1155Receiver, Clone, ERC1155 {
    using SafeTransferLib for address;

    //--------------------------------------//
    //    STORAGE - CONSTANTS/IMMUTABLES    //
    //--------------------------------------//

    /**
     * @notice Total shares that has to be minted. Each share represent 0.01%.
     */
    uint256 public constant TOTAL_SHARES = 10_000;

    /**
     * @notice Default `ITokenizedSharesRenderer` implementation, immutable.
     */
    address public immutable defaultRenderer;

    /**
     * @notice `TokenizedSharesController` contract address.
     * @dev Equivalent for 'address public immutable controller'.
     */
    function controller() public pure returns (address) {
        return _getArgAddress(0);
    }

    /**
     * @notice Keeper shares amount, max 1_000.
     * @dev Equivalent for 'uint256 public immutable keeperShares'.
     */
    function keeperShares() public pure returns (uint256) {
        return _getArgUint16(20);
    }

    /**
     * @notice `ITokenizedShares` name.
     * @dev Equivalent for 'string public (immutable) name'.
     */
    function name() public pure returns (string memory) {
        return string(_getArgBytes(86, _getArgUint256(22)));
    }

    /**
     * @notice `ITokenizedShares` symbol.
     * @dev Equivalent for 'string public (immutable) symbol'.
     */
    function symbol() public pure returns (string memory) {
        return string(_getArgBytes(86 + _getArgUint256(22), _getArgUint256(54)));
    }

    /**
     * @notice Constructor.
     * @dev Set `defaultRenderer` immutable implementation.
     */
    constructor(address renderer) {
        defaultRenderer = renderer;
    }

    //--------------------------------------//
    //              MODIFIERS               //
    //--------------------------------------//

    /**
     * @notice Allow access only from `ITokenizedSharesController` contract.
     */
    modifier controllerOnly() {
        if (msg.sender != controller()) revert ITokenizedShares__NotSharesController();
        _;
    }

    /**
     * @notice Allow access only from owner of 5001 (50% + 1) `ITokenizedShares`.
     */
    modifier onlyMajorityShareholder() {
        if (balanceOf(msg.sender, 0) < 5_001) revert ITokenizedShares__NotMajorityShareholder();
        _;
    }

    //--------------------------------------//
    //          EXTERNAL FUNCTIONS          //
    //--------------------------------------//

    /**
     * @notice Mint new shares.
     * @dev Can only be called by `controller`.
     *      Sum of `shares` must be `TOTAL_SHARES`.
     *
     * @param recipients Mint recipients.
     * @param shares Recipients shares amount.
     */
    function controllerMintShares(address[] calldata recipients, uint16[] calldata shares) external controllerOnly {
        if (recipients.length == 0) revert ITokenizedShares__NoRecipients();
        if (recipients.length != shares.length) revert ITokenizedShares__ArrayLengthsMismatch();

        uint256 i;
        uint256 totalShares;

        unchecked {
            do {
                uint256 quantity = shares[i];
                if (quantity > 0) {
                    _mint(recipients[i], 0, quantity, "");
                    totalShares += quantity;
                }
            } while (++i < recipients.length);
        }
        if (totalShares != TOTAL_SHARES) revert ITokenizedShares__InvalidSharesAmount();
    }

    /**
     * @notice Release ETH to `owners`, proportionally on how many `TokenShares` they own.
     *         If `keeperShares` was setup during initialization, distribute percentage of released to executor.
     * @dev Can only be called by `controller`.
     *
     * @param accounts Accounts to release ETH to.
     *
     * @return Keeper shares amount released.
     * @return Shares amounts released array.
     */
    function controllerReleaseShares(address[] calldata accounts)
        external
        controllerOnly
        returns (uint256, uint256[] memory)
    {
        if (accounts.length == 0) revert ITokenizedShares__NoSharesOwners();
        if (address(this).balance == 0) revert ITokenizedShares__NoBalance();

        TokenizedSharesStorage.Layout storage layout = TokenizedSharesStorage.layout();
        (
            uint256 totalAmount,
            uint256 keeperAmount,
            uint256 ownerAmount,
            uint256[] memory amounts,
            uint256[] memory fees
        ) = _releasableAmounts(layout, accounts);

        _releaseShares(layout, accounts, totalAmount, amounts, keeperAmount, ownerAmount, fees);

        return (keeperAmount, amounts);
    }

    /**
     * @notice Transfer `amount` of deposited `ITokenizedShares` to `to`.
     * @dev Can only be called by majority shareholder.
     *
     * @param to Transfer recipient.
     * @param tokenizedShares Address of `ITokenizedShares` to transfer.
     * @param amount Amount to transfer.
     */
    function transferDepositedShares(address to, address tokenizedShares, uint256 amount)
        external
        onlyMajorityShareholder
    {
        TokenizedShares(tokenizedShares).safeTransferFrom(address(this), to, 0, amount, "");
    }

    /**
     * @notice Set new custom renderer.
     * @dev Can only be called by majority shareholder.
     *
     * @param newCustomRenderer New custom renderer to be set.
     */
    function setCustomRenderer(address newCustomRenderer) external onlyMajorityShareholder {
        TokenizedSharesStorage.layout().customRenderer = newCustomRenderer;
    }

    /**
     * @notice Returns custom renderer address, returns `address(0)` if using `defaultRenderer`.
     *
     * @return Custom renderer address.
     */
    function customRenderer() external view returns (address) {
        TokenizedSharesStorage.Layout storage layout = TokenizedSharesStorage.layout();

        return layout.customRenderer;
    }

    /**
     * @notice Returns keeper fees amount for releasing `accounts` balances.
     *
     * @param accounts Shares owners to compute keeper fees on.
     *
     * @return Keeper fees.
     */
    function keeperFees(address[] calldata accounts) external view returns (uint256) {
        TokenizedSharesStorage.Layout storage layout = TokenizedSharesStorage.layout();
        (, uint256 keeperAmount,,,) = _releasableAmounts(layout, accounts);

        return keeperAmount;
    }

    /**
     * @notice Returns owner fees amount for releasing `accounts` balances.
     *
     * @param accounts Shares owners to compute owner fees on.
     *
     * @return Owner fees.
     */
    function ownerFees(address[] calldata accounts) external view returns (uint256) {
        TokenizedSharesStorage.Layout storage layout = TokenizedSharesStorage.layout();
        (,, uint256 ownerAmount,,) = _releasableAmounts(layout, accounts);

        return ownerAmount;
    }

    /**
     * @notice Returns releasable amount for `accounts`, proportionally on how many `TokenShares` they owns.
     *
     * @param accounts Shares owners to check releasable amount to.
     *
     * @return Releasable amount in ETH.
     */
    function releasable(address[] calldata accounts) external view returns (uint256[] memory) {
        TokenizedSharesStorage.Layout storage layout = TokenizedSharesStorage.layout();
        (,,, uint256[] memory amounts,) = _releasableAmounts(layout, accounts);

        return amounts;
    }

    /**
     * @notice Returns total ETH released by this contract.
     *
     * @return Total ETH released.
     */
    function totalReleased() external view returns (uint256) {
        TokenizedSharesStorage.Layout storage layout = TokenizedSharesStorage.layout();

        return layout.totalReleased;
    }

    /**
     * @notice Render `ITokenizedShares`.
     * @dev Compute uri from `customRenderer` if set, otherwise `defaultRenderer`.
     *
     * @return URI.
     */
    function uri(uint256) public view override returns (string memory) {
        TokenizedSharesStorage.Layout storage layout = TokenizedSharesStorage.layout();

        ITokenizedSharesRenderer.RenderRequest memory request = ITokenizedSharesRenderer.RenderRequest({
            tokenizedShares: address(this),
            totalReleased: layout.totalReleased,
            name: name(),
            symbol: symbol()
        });

        return layout.customRenderer == address(0)
            ? ITokenizedSharesRenderer(defaultRenderer).render(request)
            : ITokenizedSharesRenderer(layout.customRenderer).render(request);
    }

    //--------------------------------------//
    //          INTERNAL FUNCTIONS          //
    //--------------------------------------//

    /**
     * @notice Internal helper that release shares to `accounts` distributing fees for `keeper` and `owner`.
     *
     * @param layout TokenizedShares storage layout.
     * @param accounts Addresses to collect shares for.
     * @param totalAmount Total amount released including fees.
     * @param accountsAmount Array of amounts to be relased for each `account`.
     * @param keeperAmount Keeper fees.
     * @param ownerAmount Owner fees.
     */
    function _releaseShares(
        TokenizedSharesStorage.Layout storage layout,
        address[] calldata accounts,
        uint256 totalAmount,
        uint256[] memory accountsAmount,
        uint256 keeperAmount,
        uint256 ownerAmount,
        uint256[] memory feesAmount
    ) internal {
        unchecked {
            layout.totalReleased += totalAmount;

            // Release to `accounts`.
            for (uint256 i; i < accounts.length; ++i) {
                uint256 amount = accountsAmount[i];
                uint256 fees = feesAmount[i];
                address account = accounts[i];

                if (amount > 0) {
                    layout.released[account] += (amount + fees);
                    account.safeTransferETH(amount);
                }
            }

            // Release to `keeper`.
            if (keeperAmount > 0) {
                tx.origin.safeTransferETH(keeperAmount);
            }

            // Release to `owner`.
            if (ownerAmount > 0) {
                TokenizedSharesController(controller()).owner().safeTransferETH(ownerAmount);
            }
        }
    }

    /**
     * @notice Internal helper to compute releasable amounts.
     *
     * @param layout TokenizedShares storage layout.
     * @param accounts Account to check releasable amount for.
     *
     * @return Total released amount.
     * @return Keeper fees.
     * @return Owner fees.
     * @return Releasable amount per `account`.
     * @return Fees per `account`.
     */
    function _releasableAmounts(TokenizedSharesStorage.Layout storage layout, address[] calldata accounts)
        internal
        view
        returns (uint256, uint256, uint256, uint256[] memory, uint256[] memory)
    {
        unchecked {
            uint256 totalAmount;
            uint256 totalFees;
            uint256 keeperAmount;
            uint256 ownerAmount;
            uint256[] memory fees = new uint256[](accounts.length);
            uint256[] memory amounts = new uint256[](accounts.length);

            for (uint256 i; i < accounts.length; ++i) {
                (amounts[i], fees[i]) = _computeReleasableAmountAndFees(layout, accounts[i]);
                totalAmount += amounts[i];
                totalFees += fees[i];
            }

            if (totalFees > 0) {
                totalAmount += totalFees;
                keeperAmount = totalFees * 90 / 100; // 90%
                ownerAmount = totalFees - keeperAmount; // 10%
            }

            return (totalAmount, keeperAmount, ownerAmount, amounts, fees);
        }
    }

    /**
     * @notice Internal helper to compute releasable amount and fees for `account`.
     *
     * @param layout TokenizedShares storage layout.
     * @param account Account to check releasable amount for.
     *
     * @return Releasable amount.
     * @return Keeper fees.
     */
    function _computeReleasableAmountAndFees(TokenizedSharesStorage.Layout storage layout, address account)
        internal
        view
        returns (uint256, uint256)
    {
        unchecked {
            uint256 fees;

            // Cannot realistically overflow.
            uint256 weightedAccountBalance = (address(this).balance + layout.totalReleased) * balanceOf(account, 0);

            // No shares to be released when account balance is zero or no ETH.
            if (weightedAccountBalance == 0) {
                return (0, 0);
            }

            // Underflows.
            uint256 accountReleased = layout.released[account];
            if (accountReleased * TOTAL_SHARES > weightedAccountBalance) {
                return (0, 0);
            }

            // Cannot underflow.
            uint256 releasableAmount = weightedAccountBalance / TOTAL_SHARES - accountReleased;

            // Compute `fees` and subtract them from `weightedAccountBalance`.
            if (keeperShares() > 0) {
                fees = releasableAmount * keeperShares() / TOTAL_SHARES;
                releasableAmount = releasableAmount - fees;
            }

            return (releasableAmount, fees);
        }
    }

    /**
     * @notice See `ERC1155._useBeforeTokenTransfer`
     */
    function _useBeforeTokenTransfer() internal pure override returns (bool) {
        return true;
    }

    /**
     * @notice `ERC1155._beforeTokenTransfer` override.
     * @dev Transfer `from` collected weighted amount to `to` to prevent collecting twice with same shares.
     */
    function _beforeTokenTransfer(address from, address to, uint256[] memory, uint256[] memory amounts, bytes memory)
        internal
        override
    {
        unchecked {
            uint256 transferAmount = amounts[0];
            uint256 fromBalance = balanceOf(from, 0);

            if (fromBalance < transferAmount) {
                return;
            }

            TokenizedSharesStorage.Layout storage layout = TokenizedSharesStorage.layout();
            uint256 amountWeightedReleased = transferAmount * layout.released[from] / fromBalance;

            // Cannot underflow since fromBalance >= transferAmount
            layout.released[from] -= amountWeightedReleased;

            // Cannot realistically overflow
            layout.released[to] += amountWeightedReleased;
        }
    }

    //--------------------------------------//
    //          IERC1155Receiver            //
    //--------------------------------------//

    /**
     * @notice Allows to receive `ITokenizedShares`.
     * @dev Reverts when receiving invalid `ITokenizedShares`.
     *
     * @return Function signature for `onERC1155Received`, `0xf23a6e61`.
     */
    function onERC1155Received(address, address, uint256 id, uint256 value, bytes calldata)
        external
        view
        returns (bytes4)
    {
        if (id == 0 && value <= TOTAL_SHARES) {
            try ITokenizedShares(msg.sender).supportsInterface(type(ITokenizedShares).interfaceId) returns (
                bool success
            ) {
                // 0xf23a6e61: `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`.
                if (success) return 0xf23a6e61;
            } catch {
                // pass
            }
        }

        revert ITokenizedShares__InvalidDeposit();
    }

    /**
     * @notice Allows to batch receive `ITokenizedShares`.
     * @dev Reverts when receiving invalid `ITokenizedShares`.
     *     
     * @return Function signature for `onERC1155BatchReceived`, `0xbc197c81`.
     */
    function onERC1155BatchReceived(address, address, uint256[] calldata ids, uint256[] calldata values, bytes calldata)
        external
        view
        returns (bytes4)
    {
        if (ids.length == 1 && ids[0] == 0 && values[0] <= TOTAL_SHARES) {
            try ITokenizedShares(msg.sender).supportsInterface(type(ITokenizedShares).interfaceId) returns (
                bool success
            ) {
                // 0xbc197c81: `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`.
                if (success) return 0xbc197c81;
            } catch {
                // pass
            }
        }

        revert ITokenizedShares__InvalidDeposit();
    }

    //--------------------------------------//
    //          ERC165                      //
    //--------------------------------------//

    /**
     * @dev Supports: `IERC165`, `ITokenizedShares`, `IERC1155`, `IERC1155Receiver`, `IERC1155MetadataURI`.
     */
    function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC1155) returns (bool) {
        return interfaceId == type(ITokenizedShares).interfaceId || type(IERC1155Receiver).interfaceId == interfaceId
            || ERC1155.supportsInterface(interfaceId);
    }
}
