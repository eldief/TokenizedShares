// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {ITokenizedSharesRenderer, TokenizedSharesRenderer, SSTORE2} from "../src/TokenizedSharesRenderer.sol";
import {ITokenizedShares, TokenizedShares} from "../src/TokenizedShares.sol";
import {ITokenizedSharesController, TokenizedSharesController} from "../src/TokenizedSharesController.sol";

// forge script ./script/Deploy.s.sol:DeployScript -vvvv --broadcast --verify --rpc-url ${GOERLI_RPC_URL}
contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        TokenizedSharesRenderer renderer = new TokenizedSharesRenderer();
        TokenizedShares tokenizedShares = new TokenizedShares(address(renderer));
        TokenizedSharesController sharesFactory = new TokenizedSharesController(address(tokenizedShares));

        vm.stopBroadcast();

        console.log("TokenizedSharesRenderer deployed at:", address(renderer));
        console.log("TokenizedSharesRenderer deployed at:", address(tokenizedShares));
        console.log("TokenizedSharesController deployed at:", address(sharesFactory));
    }
}
