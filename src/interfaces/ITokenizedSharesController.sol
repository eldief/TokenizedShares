// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITokenizedSharesController.
 * @author @eldief
 * @notice ITokenizedSharesController interface.
 */
interface ITokenizedSharesController {
    //--------------------------------------//
    //               ERRORS                 //
    //--------------------------------------//
    error ITokenizedSharesController__InvalidKeeperShares();

    //--------------------------------------//
    //               EVENTS                 //
    //--------------------------------------//
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

    //--------------------------------------//
    //            CONSTANTS                 //
    //--------------------------------------//
    function MAX_KEEPER_SHARES() external pure returns (uint256);

    //--------------------------------------//
    //           IMMUTABLES                 //
    //--------------------------------------//
    function implementation() external view returns (address);

    //--------------------------------------//
    //            FUNCTIONS                 //
    //--------------------------------------//
    function addTokenizedShares(
        uint16 keeperShares,
        address[] calldata recipients,
        uint16[] calldata shares,
        string calldata name,
        string calldata symbol
    ) external returns (address);

    function releaseShares(address[] calldata accounts) external;
    function releaseShares(address[] calldata accounts, address[] calldata tokenizedShares) external;

    function keeperFees(address[] calldata accounts) external view returns (address[] memory, uint256[] memory);
    function keeperFees(address[] calldata accounts, address[] calldata tokenizedShares)
        external
        view
        returns (address[] memory, uint256[] memory);

    function keeperShares() external view returns (address[] memory, uint256[] memory);
    function keeperShares(address[] calldata tokenizedShares)
        external
        view
        returns (address[] memory, uint256[] memory);

    function releasable(address[] calldata accounts) external view returns (address[] memory, uint256[][] memory);
    function releasable(address[] calldata accounts, address[] calldata tokenizedShares)
        external
        view
        returns (address[] memory, uint256[][] memory);

    function sharesOwned(address[] calldata accounts) external view returns (address[] memory, uint256[][] memory);
    function sharesOwned(address[] calldata accounts, address[] calldata tokenizedShares)
        external
        view
        returns (address[] memory, uint256[][] memory);
}
