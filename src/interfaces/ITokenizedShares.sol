// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title ITokenizedShares.
 * @author @eldief.
 * @notice Base interface that has to inherited by `TokenizedShares` specialized contracts.
 */
interface ITokenizedShares {
    //--------------------------------------//
    //               ERRORS                 //
    //--------------------------------------//
    error ITokenizedShares__ArrayLengthsMismatch();
    error ITokenizedShares__InvalidSharesAmount();
    error ITokenizedShares__NoBalance();
    error ITokenizedShares__NoRecipients();
    error ITokenizedShares__NoSharesOwners();
    error ITokenizedShares__NotSharesFactory();

    //--------------------------------------//
    //            FUNCTIONS                 //
    //--------------------------------------//
    function factoryMintShares(address[] calldata recipients, uint256[] calldata shares) external;
    function releaseShares(address[] calldata owners) external;
    function releasable(address owner) external view returns (uint256);
    function totalReleased() external view returns (uint256);

    //--------------------------------------//
    //            CONSTANTS                 //
    //--------------------------------------//
    function TOTAL_SHARES() external pure returns (uint256);

    //--------------------------------------//
    //           IMMUTABLES                 //
    //--------------------------------------//
    function customData() external pure returns (bytes memory);
    function factory() external pure returns (address);
    function keeperShares() external pure returns (uint256);
}
