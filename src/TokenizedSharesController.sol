// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITokenizedShares} from "./interfaces/ITokenizedShares.sol";
import {ITokenizedSharesController} from "./interfaces/ITokenizedSharesController.sol";
import {TokenizedSharesControllerStorage} from "./libraries/TokenizedSharesControllerStorage.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {ERC1155} from "solady/tokens/ERC1155.sol";
import {LibClone} from "solady/utils/LibClone.sol";

/**
 * @title TokenizedSharesController.
 * @author @eldief
 * @notice Efficiently create new `ITokenizedShares` and batch reads.
 */
contract TokenizedSharesController is ITokenizedSharesController, Ownable {
    //--------------------------------------//
    //    STORAGE - CONSTANTS/IMMUTABLES    //
    //--------------------------------------//

    /**
     * @notice Max amount of shares to reward keeper.
     *         Each share represent 0.01%, max 10%.
     */
    uint256 public constant MAX_KEEPER_SHARES = 1_000;

    /**
     * @notice Immutable `ITokenizedShares` implementation address.
     */
    address public immutable implementation;

    //--------------------------------------//
    //          CONSTRUCTOR                 //
    //--------------------------------------//

    constructor(address implementation_) {
        implementation = implementation_;
        _initializeOwner(msg.sender);
    }

    //--------------------------------------//
    //          EXTERNAL FUNCTIONS          //
    //--------------------------------------//

    /**
     * @notice Clone and initialize new `ITokenizedShares` contract setting keeper fees.
     * @dev Maximum value for `keeperShares_` is `MAX_KEEPER_SHARES`.
     *      Sum of `shares` must be exactly `ITokenizedShares.TOTAL_SHARES`.
     *
     * @param keeperShares_ Shares reserved for keeper.
     * @param recipients Mint recipients.
     * @param shares Recipients shares amount.
     * @param name `ITokenizedShares` name.
     * @param symbol `ITokenizedShares` symbol.
     *
     * @return tokenizedShares Cloned `ITokenizedShares` address.
     */
    function addTokenizedShares(
        uint16 keeperShares_,
        address[] calldata recipients,
        uint16[] calldata shares,
        string calldata name,
        string calldata symbol
    ) external returns (address) {
        if (keeperShares_ > MAX_KEEPER_SHARES) revert ITokenizedSharesController__InvalidKeeperShares();

        uint256 nameLength = bytes(name).length;
        uint256 symbolLength = bytes(symbol).length;

        address tokenizedShares = LibClone.clone(
            implementation, abi.encodePacked(address(this), keeperShares_, nameLength, symbolLength, name, symbol)
        );

        TokenizedSharesControllerStorage.layout().tokenizedShares.push(tokenizedShares);

        ITokenizedShares(tokenizedShares).controllerMintShares(recipients, shares);

        emit NewTokenizedShares(tokenizedShares, keeperShares_, recipients, shares);

        return tokenizedShares;
    }

    /**
     * @notice Release ETH accrued by all `ITokenizedShares` to `accounts`.
     *
     * @param accounts Shares owners to release ETH to.
     */
    function releaseShares(address[] calldata accounts) external {
        address[] memory tokenizedShares = TokenizedSharesControllerStorage.layout().tokenizedShares;

        _releaseShares(accounts, tokenizedShares);
    }

    /**
     * @notice Release ETH accrued by `tokenizedShares` to `accounts`.
     *
     * @param tokenizedShares `ITokenizedShares` contract addresses.
     * @param accounts Shares owners to release ETH to.
     */
    function releaseShares(address[] calldata accounts, address[] calldata tokenizedShares) external {
        _releaseShares(accounts, tokenizedShares);
    }

    /**
     * @notice Returns keeper fees amount for releasing all `ITokenizedShares`.
     *
     * @param accounts Accounts to simulate shares releasing.
     *
     * @return `ITokenizedShares` contract addresses.
     * @return Keeper fees.
     */
    function keeperFees(address[] calldata accounts) external view returns (address[] memory, uint256[] memory) {
        address[] memory tokenizedShares = TokenizedSharesControllerStorage.layout().tokenizedShares;
        uint256[] memory amounts = _keeperFees(accounts, tokenizedShares);

        return (tokenizedShares, amounts);
    }

    /**
     * @notice Returns keeper fees amount for releasing `tokenizedShares`.
     *
     * @param accounts Accounts to simulate shares releasing.
     * @param tokenizedShares `ITokenizedShares` contract addresses.
     *
     * @return `ITokenizedShares` contract addresses.
     * @return Keeper fees.
     */
    function keeperFees(address[] calldata accounts, address[] calldata tokenizedShares)
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256[] memory amounts = _keeperFees(accounts, tokenizedShares);

        return (tokenizedShares, amounts);
    }

    /**
     * @notice Returns 'keeperShares' quantity for all `ITokenizedShares`.
     *
     * @return `ITokenizedShares` contract addresses.
     * @return Keeper shares.
     */
    function keeperShares() external view returns (address[] memory, uint256[] memory) {
        address[] memory tokenizedShares = TokenizedSharesControllerStorage.layout().tokenizedShares;
        uint256[] memory amounts = _keeperShares(tokenizedShares);

        return (tokenizedShares, amounts);
    }

    /**
     * @notice Returns 'keeperShares' quantity for 'tokenizedShares`.
     *
     * @param tokenizedShares `ITokenizedShares` contract addresses.
     *
     * @return `ITokenizedShares` contract addresses.
     * @return Keeper shares.
     */
    function keeperShares(address[] calldata tokenizedShares)
        external
        pure
        returns (address[] memory, uint256[] memory)
    {
        uint256[] memory amounts = _keeperShares(tokenizedShares);

        return (tokenizedShares, amounts);
    }

    /**
     * @notice Returns `accounts` releasable amount for all `ITokenizedShares`.
     *
     * @param accounts Accounts to check releasable amount for.
     *
     * @return `ITokenizedShares` contract addresses.
     * @return Releasable amounts.
     */
    function releasable(address[] calldata accounts) external view returns (address[] memory, uint256[][] memory) {
        address[] memory tokenizedShares = TokenizedSharesControllerStorage.layout().tokenizedShares;
        uint256[][] memory amounts = _releasable(accounts, tokenizedShares);

        return (tokenizedShares, amounts);
    }

    /**
     * @notice Returns `accounts` releasable amount accrued by `tokenizedShares`.
     *
     * @param accounts Accounts to check releasable amount for.
     * @param tokenizedShares `ITokenizedShares` contract addresses.
     *
     * @return `ITokenizedShares` contract addresses.
     * @return Releasable amounts.
     */
    function releasable(address[] calldata accounts, address[] calldata tokenizedShares)
        external
        view
        returns (address[] memory, uint256[][] memory)
    {
        uint256[][] memory amounts = _releasable(accounts, tokenizedShares);

        return (tokenizedShares, amounts);
    }

    /**
     * @notice Returns balance of all `ITokenizedShares` owned by `accounts`.
     *
     * @param accounts Accounts to check balance for.
     *
     * @return `ITokenizedShares` contract addresses.
     * @return Balances of `accounts`.
     */
    function sharesOwned(address[] calldata accounts) external view returns (address[] memory, uint256[][] memory) {
        address[] memory tokenizedShares = TokenizedSharesControllerStorage.layout().tokenizedShares;
        uint256[][] memory balances = _sharesOwned(accounts, tokenizedShares);

        return (tokenizedShares, balances);
    }

    /**
     * @notice Returns balance of `tokenizedShares` owned by `accounts`.
     *
     * @param accounts Accounts to check balance for.
     * @param tokenizedShares `ITokenizedShares` contract addresses.
     *
     * @return `ITokenizedShares` contract addresses.
     * @return Balances of `accounts`.
     */
    function sharesOwned(address[] calldata accounts, address[] calldata tokenizedShares)
        external
        view
        returns (address[] memory, uint256[][] memory)
    {
        uint256[][] memory balances = _sharesOwned(accounts, tokenizedShares);

        return (tokenizedShares, balances);
    }

    //--------------------------------------//
    //          INTERNAL FUNCTIONS          //
    //--------------------------------------//

    /**
     * @notice Internal helper to release ETH accrued by `ITokenizedShares` contracts to `accounts`.
     *
     * @param accounts Shares owners to release ETH to.
     * @param tokenizedShares `ITokenizedShares` contract addresses.
     */
    function _releaseShares(address[] calldata accounts, address[] memory tokenizedShares) internal {
        uint256 accountsLength = accounts.length;
        uint256 tokenizedSharesLength = tokenizedShares.length;

        uint256[] memory keeperAmounts = new uint256[](tokenizedSharesLength);
        uint256[][] memory amounts = new uint256[][](tokenizedSharesLength);

        unchecked {
            for (uint256 i; i < tokenizedSharesLength; ++i) {
                try ITokenizedShares(tokenizedShares[i]).controllerReleaseShares(accounts) returns (
                    uint256 keeperAmount, uint256[] memory amount
                ) {
                    keeperAmounts[i] = keeperAmount;
                    amounts[i] = amount;
                } catch {
                    amounts[i] = new uint256[](accountsLength);
                }
            }
        }
        emit SharesReleased(tokenizedShares, tx.origin, keeperAmounts, accounts, amounts);
    }

    /**
     * @notice Internal helper that returns keeper fees amount for releasing `tokenizedShares` to 'accounts'.
     *
     * @param accounts Accounts to simulate shares releasing.
     * @param tokenizedShares `ITokenizedShares` contract addresses.
     *
     * @return Keeper fees.
     */
    function _keeperFees(address[] calldata accounts, address[] memory tokenizedShares)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 tokenizedSharesLength = tokenizedShares.length;
        uint256[] memory amounts = new uint256[](tokenizedSharesLength);

        unchecked {
            for (uint256 i; i < tokenizedSharesLength; ++i) {
                try ITokenizedShares(tokenizedShares[i]).keeperFees(accounts) returns (uint256 amount) {
                    amounts[i] = amount;
                } catch {
                    // pass
                }
            }
        }
        return amounts;
    }

    /**
     * @notice Internal helper that returns 'keeperShares' quantity for 'tokenizedShares`.
     *
     * @param tokenizedShares `ITokenizedShares` contract addresses.
     *
     * @return Keeper shares.
     */
    function _keeperShares(address[] memory tokenizedShares) internal pure returns (uint256[] memory) {
        uint256 tokenizedSharesLength = tokenizedShares.length;
        uint256[] memory amounts = new uint256[](tokenizedSharesLength);

        unchecked {
            for (uint256 i; i < tokenizedSharesLength; ++i) {
                try ITokenizedShares(tokenizedShares[i]).keeperShares() returns (uint256 amount) {
                    amounts[i] = amount;
                } catch {
                    // pass
                }
            }
        }
        return amounts;
    }

    /**
     * @notice Internal helper to retrieve `tokenizedShares` releasable amount for `accounts`.
     *
     * @param accounts Shares owner to release ETH to.
     * @param tokenizedShares `ITokenizedShares` contract addresses.
     *
     * @return Releasable amounts.
     */
    function _releasable(address[] calldata accounts, address[] memory tokenizedShares)
        internal
        view
        returns (uint256[][] memory)
    {
        uint256 accountsLength = accounts.length;
        uint256 tokenizedSharesLength = tokenizedShares.length;

        uint256[][] memory amounts = new uint256[][](tokenizedSharesLength);

        unchecked {
            for (uint256 i; i < tokenizedSharesLength; ++i) {
                try ITokenizedShares(tokenizedShares[i]).releasable(accounts) returns (uint256[] memory amount) {
                    amounts[i] = amount;
                } catch {
                    amounts[i] = new uint256[](accountsLength);
                }
            }
        }
        return amounts;
    }

    /**
     * @notice Internal helper to retrieve balance of `tokenizedShares` owned by `accounts`.
     *
     * @param accounts Accounts to check balance for.
     * @param tokenizedShares `ITokenizedShares` contract addresses.
     *
     * @return Balances of `accounts`.
     */
    function _sharesOwned(address[] calldata accounts, address[] memory tokenizedShares)
        internal
        view
        returns (uint256[][] memory)
    {
        uint256 accountsLength = accounts.length;
        uint256 tokenizedSharesLength = tokenizedShares.length;

        uint256[][] memory balances = new uint256[][](tokenizedSharesLength);

        unchecked {
            for (uint256 i; i < tokenizedSharesLength; ++i) {
                try ERC1155(tokenizedShares[i]).balanceOfBatch(accounts, new uint256[](accountsLength)) returns (
                    uint256[] memory balance
                ) {
                    balances[i] = balance;
                } catch {
                    balances[i] = new uint256[](accountsLength);
                }
            }
        }
        return balances;
    }
}
