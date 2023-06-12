// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/ISharesFactory.sol";
import "./interfaces/ITokenizedShares.sol";
import "./libraries/SharesFactoryStorage.sol";
import "solady/utils/LibClone.sol";
import "solady/tokens/ERC1155.sol";

/**
 * @title SharesFactory.
 * @author @eldief
 * @notice Factory contract to efficiently generate new `ITokenizedShares` clones.
 */
contract SharesFactory is ISharesFactory {
    //--------------------------------------//
    //    STORAGE - CONSTANTS/IMMUTABLES    //
    //--------------------------------------//

    /**
     * @notice Max amount of shares to reward keeper.
     *         Each share represent 0.01%.
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
    }

    //--------------------------------------//
    //          EXTERNAL FUNCTIONS          //
    //--------------------------------------//

    /**
     * @notice Clone new `ITokenizedShares` contract setting no keeper fees.
     *         Mint `ITokenizedShares` tokens to `recipients`.
     *         Both ERC20 and ERC1155 versions of `ITokenizedShares` are supported.
     * @dev Sum of `shares` must be exactly `10_000`.
     *
     * @param recipients Mint recipients.
     * @param shares Recipients shares amount.
     * 
     * @return tokenizedShares Cloned `ITokenizedShares` address.
     */
    function addTokenizedShares(address[] calldata recipients, uint256[] calldata shares) external returns (address) {
        return _addTokenizedShares(0, recipients, shares, _emptyCalldata());
    }

    /**
     * @notice Clone new `ITokenizedShares` contract setting no keeper fees.
     *         Mint `ITokenizedShares` tokens to `recipients`.
     *         Both ERC20 and ERC1155 versions of `ITokenizedShares` are supported.
     * @dev Sum of `shares` must be exactly `10_000`.
     *
     * @param recipients Mint recipients.
     * @param shares Recipients shares amount.
     * @param customData User defined encoded data.
     * 
     * @return tokenizedShares Cloned `ITokenizedShares` address.
     */
    function addTokenizedShares(address[] calldata recipients, uint256[] calldata shares, bytes calldata customData) external returns (address) {
        return _addTokenizedShares(0, recipients, shares, customData);
    }

    /**
     * @notice Clone and initialize new `ITokenizedShares` contract setting keeper fees.
     * @dev Maximum value for `keeperShares` is `MAX_KEEPER_SHARES`.
     *      Sum of `keeperShares` and `shares` must be exactly `ITokenizedShares.TOTAL_SHARES`.
     *
     * @param keeperShares Shares reserved for keeper.
     * @param recipients Mint recipients.
     * @param shares Recipients shares amount.
     * 
     * @return tokenizedShares Cloned `ITokenizedShares` address.
     */
    function addTokenizedShares(uint256 keeperShares, address[] calldata recipients, uint256[] calldata shares)
        external
        returns (address)
    {
        if (keeperShares > MAX_KEEPER_SHARES) revert ISharesFactory__InvalidKeeperShares();
        return _addTokenizedShares(keeperShares, recipients, shares, _emptyCalldata());
    }

    /**
     * @notice Clone and initialize new `ITokenizedShares` contract setting keeper fees.
     * @dev Maximum value for `keeperShares` is `MAX_KEEPER_SHARES`.
     *      Sum of `keeperShares` and `shares` must be exactly `ITokenizedShares.TOTAL_SHARES`.
     *
     * @param keeperShares Shares reserved for keeper.
     * @param recipients Mint recipients.
     * @param shares Recipients shares amount.
     * @param customData User defined encoded data.
     * 
     * @return tokenizedShares Cloned `ITokenizedShares` address.
     */
    function addTokenizedShares(uint256 keeperShares, address[] calldata recipients, uint256[] calldata shares, bytes calldata customData)
        external
        returns (address)
    {
        if (keeperShares > MAX_KEEPER_SHARES) revert ISharesFactory__InvalidKeeperShares();
        return _addTokenizedShares(keeperShares, recipients, shares, customData);
    }

    /**
     * @notice Release ETH accrued by all `ITokenizedShares` to `owners`.
     *
     * @param owners Shares owners to release ETH to.
     */
    function releaseShares(address[] calldata owners) external {
        address[] memory tokenizedShares = SharesFactoryStorage.layout().tokenizedShares;
        if (tokenizedShares.length == 0) revert ISharesFactory__NoTokenShares();

        _releaseShares(tokenizedShares, owners);
    }

    /**
     * @notice Release ETH accrued by `tokenizedShares` to `owners`.
     *
     * @param tokenizedShares `ITokenizedShares` contract addresses.
     * @param owners Shares owners to release ETH to.
     */
    function releaseShares(address[] calldata tokenizedShares, address[] calldata owners) external {
        if (tokenizedShares.length == 0) revert ISharesFactory__NoTokenShares();

        _releaseShares(tokenizedShares, owners);
    }

    //--------------------------------------//
    //          INTERNAL FUNCTIONS          //
    //--------------------------------------//

    /**
     * @notice Internal helper to mint `ITokenizedShares`.
     *
     * @param keeperShares Shares reserved for keeper.
     * @param recipients Mint recipients.
     * @param shares Recipients shares amount.
     * @param customData User defined encoded data to be stored in bytecode.
     * 
     * @return tokenizedShares Cloned `ITokenizedShares` address.
     */
    function _addTokenizedShares(uint256 keeperShares, address[] calldata recipients, uint256[] calldata shares, bytes calldata customData)
        internal
        returns (address tokenizedShares)
    {
        tokenizedShares = LibClone.clone(implementation, abi.encode(address(this), keeperShares, customData));
        SharesFactoryStorage.layout().tokenizedShares.push(tokenizedShares);

        ITokenizedShares(tokenizedShares).factoryMintShares(recipients, shares);
        emit NewTokenizedShares(tokenizedShares);
    }

    /**
     * @notice Internal helper to release ETH accrued by `ITokenizedShares` contracts to `owners`.
     *
     * @param tokenizedShares `ITokenizedShares` contract addresses.
     * @param owners Shares owners to release ETH to.
     */
    function _releaseShares(address[] memory tokenizedShares, address[] calldata owners) internal {
        uint256 i;
        uint256 length = tokenizedShares.length;

        unchecked {
            do {
                ITokenizedShares(tokenizedShares[i]).releaseShares(owners);

                ++i;
            } while (i < length);
        }
    }

    /**
     * @notice Internal helper to to return an empty bytes calldata.
     *         See: https://github.com/Vectorized/solady/blob/6d706e05ef43cbed234c648f83c55f3a4bb0a520/src/utils/ERC1967Factory.sol#L433.
     * 
     * @return data Empty calldata.
     */
    function _emptyCalldata() internal pure returns (bytes calldata data) {
        assembly {
            data.length := 0
        }
    }
}
