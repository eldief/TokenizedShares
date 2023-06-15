// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/ITokenizedShares.sol";
import "./libraries/TokenizedSharesStorage.sol";
import "solady/utils/Clone.sol";
import "solady/utils/SafeTransferLib.sol";
import "solady/tokens/ERC20.sol";

/**
 * @title ERC20TokenizedShares.
 * @author @eldief
 * @notice Abstract Template ERC20 defining Tokenized Shares functionalities.
 */
abstract contract ERC20TokenizedShares is ITokenizedShares, Clone, ERC20 {
    using SafeTransferLib for address;

    //--------------------------------------//
    //    STORAGE - CONSTANTS/IMMUTABLES    //
    //--------------------------------------//

    /**
     * @notice Total shares that has to be minted.
     *         Each share represent 0.01%.
     */
    uint256 public constant TOTAL_SHARES = 10_000 * 1e18;

    /**
     * @notice `SharesFactory` contract address.
     * @dev Equivalent for 'address public immutable factory'.
     */
    function factory() public pure returns (address) {
        return _getArgAddress(0);
    }

    /**
     * @notice Keeper shares amount.
     * @dev Equivalent for 'uint256 public immutable keeperShares'.
     */
    function keeperShares() public pure returns (uint256) {
        return _getArgUint16(20) * 10 ** decimals();
    }

    //--------------------------------------//
    //              MODIFIERS               //
    //--------------------------------------//

    /**
     * @notice Allow access only from `SharesMaster` contract.
     */
    modifier onlySharesMaster() {
        if (msg.sender != factory()) revert ITokenizedShares__NotSharesFactory();
        _;
    }

    //--------------------------------------//
    //           EXTERNAL VIEW              //
    //--------------------------------------//

    /**
     * @notice Returns decimals places of the token.
     * @dev This function is not overrideable.
     */
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    //--------------------------------------//
    //          EXTERNAL FUNCTIONS          //
    //--------------------------------------//

    /**
     * @notice Mint new shares.
     * @dev Sum of shares must be equal to `TOTAL_SHARES`.
     *      Sum of `keeperShares` and `shares` must be exactly `MAX_KEEPER_SHARES`.
     *
     * @param recipients Mint recipients.
     * @param shares Recipients shares amount.
     */
    function factoryMintShares(address[] calldata recipients, uint16[] calldata shares) external onlySharesMaster {
        uint256 length = recipients.length;
        if (length == 0) revert ITokenizedShares__NoRecipients();
        if (length != shares.length) revert ITokenizedShares__ArrayLengthsMismatch();

        uint256 i;
        unchecked {
            do {
                uint256 quantity = shares[i] * 10 ** decimals();

                if (quantity > 0) {
                    _mint(recipients[i], quantity);
                }

                ++i;
            } while (i < length);
        }
        if (totalSupply() + keeperShares() != TOTAL_SHARES) revert ITokenizedShares__InvalidSharesAmount();
    }

    /**
     * @notice Release ETH to `owners`, proportionally on how many `TokenShares` they own.
     *         If `keeperShares` was setup during cloning, release proportionally shares to call executor.
     *
     * @param owners Shares owners to release ETH to.
     */
    function releaseShares(address[] calldata owners) external {
        uint256 length = owners.length;
        if (length == 0) revert ITokenizedShares__NoSharesOwners();
        if (address(this).balance == 0) revert ITokenizedShares__NoBalance();

        TokenizedSharesStorage.Layout storage layout = TokenizedSharesStorage.layout();

        uint256 released = _releaseOwnersShares(layout, owners, length);
        if (released > 0) {
            _releaseKeeperShares(layout, released);
        }
    }

    /**
     * @notice Returns releasable amount for `owner`, proportionally on how many `TokenShares` he owns.
     *
     * @param owner Account to check releasable amount for.
     * @return Releasable amount in ETH.
     */
    function releasable(address owner) external view returns (uint256) {
        TokenizedSharesStorage.Layout storage layout = TokenizedSharesStorage.layout();
        return _releasable(layout, owner);
    }

    /**
     * @notice Returns total ETH released by this contract.
     *
     * @return Total ETH released.
     */
    function totalReleased() external view returns (uint256) {
        TokenizedSharesStorage.Layout storage layout = TokenizedSharesStorage.layout();
        return _totalReleased(layout);
    }

    //--------------------------------------//
    //          INTERNAL FUNCTIONS          //
    //--------------------------------------//

    /**
     * @notice Internal helper that release shares to `owners`.
     *
     * @param layout TokenizedShares storage layout.
     * @param owners Address to collect shares for.
     * @param length Amount of owners to collect for.
     *
     * @return released Shares amount released to owners.
     */
    function _releaseOwnersShares(
        TokenizedSharesStorage.Layout storage layout,
        address[] calldata owners,
        uint256 length
    ) internal returns (uint256 released) {
        uint256 i;

        do {
            address owner = owners[i];
            uint256 amount = _releasable(layout, owner);

            // Cannot realistically overflow.
            unchecked {
                if (amount > 0) {
                    released += amount;
                    layout.totalReleased += amount;
                    layout.released[owner] += amount;

                    owner.safeTransferETH(amount);
                }
                ++i;
            }
        } while (i < length);
    }

    /**
     * @notice Internal helper that release shares to keeper, if set during contract cloning.
     *
     * @param layout TokenizedShares storage layout.
     * @param released Shares amount released to owners.
     */
    function _releaseKeeperShares(TokenizedSharesStorage.Layout storage layout, uint256 released) internal {
        uint256 sharesBalance = keeperShares();

        // Cannot realistically overflow.
        unchecked {
            if (sharesBalance > 0) {
                uint256 amount = released * sharesBalance / TOTAL_SHARES;

                if (amount > 0) {
                    layout.totalReleased += amount;
                    tx.origin.safeTransferETH(amount);
                }
            }
        }
    }

    /**
     * @notice Internal helper to compute releasable amount.
     *
     * @param owner Account to check releasable amount for.
     * @return Releasable amount in ETH.
     */
    function _releasable(TokenizedSharesStorage.Layout storage layout, address owner) internal view returns (uint256) {
        uint256 balance = address(this).balance;

        // Cannot realistically overflow.
        uint256 weightedOwnerBalance;
        unchecked {
            weightedOwnerBalance = (balance + _totalReleased(layout)) * balanceOf(owner);
        }

        // No shares to be released when owner's balance is zero or no ETH.
        if (weightedOwnerBalance == 0) {
            return 0;
        }

        // Will underflow, so no ETH to be released.
        uint256 ownerReleased = layout.released[owner];
        if (ownerReleased * TOTAL_SHARES > weightedOwnerBalance) {
            return 0;
        }

        // Cannot underflow.
        unchecked {
            return weightedOwnerBalance / TOTAL_SHARES - ownerReleased;
        }
    }

    /**
     * @notice Internal helper to return total ETH released by this contract.
     *
     * @param layout TokenizedShares storage layout.
     * @return Total ETH released.
     */
    function _totalReleased(TokenizedSharesStorage.Layout storage layout) internal view returns (uint256) {
        return layout.totalReleased;
    }

    /**
     * @notice `ERC20._beforeTokenTransfer` override.
     * @dev Transfer `from` collected weighted amount to `to` to prevent collecting twice with same shares.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        uint256 fromBalance = balanceOf(from);
        TokenizedSharesStorage.Layout storage layout = TokenizedSharesStorage.layout();

        unchecked {
            if (fromBalance > amount) {
                uint256 amountWeightedReleased = amount * layout.released[from] / fromBalance;

                // Cannot underflow since fromBalance >= amount
                layout.released[from] -= amountWeightedReleased;

                // Cannot realistically overflow
                layout.released[to] += amountWeightedReleased;
            }
        }
    }
}
