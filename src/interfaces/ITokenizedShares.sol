// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

/**
 * @title ITokenizedShares.
 * @author @eldief.
 * @notice TokenizedShare interface.
 */
interface ITokenizedShares is IERC165 {
    //--------------------------------------//
    //               ERRORS                 //
    //--------------------------------------//
    error ITokenizedShares__ArrayLengthsMismatch();
    error ITokenizedShares__InvalidDeposit();
    error ITokenizedShares__InvalidSharesAmount();
    error ITokenizedShares__NoBalance();
    error ITokenizedShares__NoRecipients();
    error ITokenizedShares__NotMajorityShareholder();
    error ITokenizedShares__NoSharesOwners();
    error ITokenizedShares__NotSharesController();

    //--------------------------------------//
    //            CONSTANTS                 //
    //--------------------------------------//
    function TOTAL_SHARES() external pure returns (uint256);

    //--------------------------------------//
    //           IMMUTABLES                 //
    //--------------------------------------//
    function controller() external pure returns (address);
    function defaultRenderer() external view returns (address);
    function keeperShares() external pure returns (uint256);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);

    //--------------------------------------//
    //            FUNCTIONS                 //
    //--------------------------------------//
    function controllerMintShares(address[] calldata recipients, uint16[] calldata shares) external;
    function controllerReleaseShares(address[] calldata accounts) external returns (uint256, uint256[] memory);
    function setCustomRenderer(address customRenderer) external;
    function transferDepositedShares(address to, address tokenizedShares, uint256 amount) external;

    function customRenderer() external view returns (address);
    function keeperFees(address[] calldata accounts) external view returns (uint256);
    function ownerFees(address[] calldata accounts) external view returns (uint256);
    function releasable(address[] calldata accounts) external view returns (uint256[] memory);
    function totalReleased() external view returns (uint256);
}
