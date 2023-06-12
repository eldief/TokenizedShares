// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title ISharesFactory.
 * @author @eldief
 * @notice SharesFactory interface.
 */
interface ISharesFactory {
    //--------------------------------------//
    //               ERRORS                 //
    //--------------------------------------//
    error ISharesFactory__InvalidKeeperShares();
    error ISharesFactory__NoTokenShares();

    //--------------------------------------//
    //               EVENTS                 //
    //--------------------------------------//
    event NewTokenizedShares(address tokenizedShares);

    //--------------------------------------//
    //            FUNCTIONS                 //
    //--------------------------------------//
    function addTokenizedShares(address[] calldata recipients, uint256[] calldata shares) external returns (address);
    function addTokenizedShares(uint256 keeperShares, address[] calldata recipients, uint256[] calldata shares)
        external
        returns (address);

    function releaseShares(address[] calldata owners) external;
    function releaseShares(address[] calldata tokenShares, address[] calldata owners) external;

    //--------------------------------------//
    //            CONSTANTS                 //
    //--------------------------------------//
    function MAX_KEEPER_SHARES() external pure returns (uint256);

    //--------------------------------------//
    //           IMMUTABLES                 //
    //--------------------------------------//
    function implementation() external view returns (address);
}
