// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TokenizedSharesController} from "../TokenizedSharesController.sol";
import "solady/tokens/ERC721.sol";

interface IERC2981 {
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

/**
 * @title CollectionTokenizedRoyalties.
 * @author @eldief
 * @notice Example for collection TokenizedRoyalties.
 */
contract CollectionTokenizedRoyalties is ERC721, IERC2981 {
    address public immutable tokenizedShares;

    uint256 public constant ROYALTIES_BPS = 1_000; // 10%

    constructor(address factory_, address[] memory recipients, uint16[] memory shares) {
        // Reference ITokenizedSharesFactory implementation
        TokenizedSharesController controller = TokenizedSharesController(factory_);

        // Create new ITokenizedShares with 5% keeperShares and distribute `shares` to `recipients`
        tokenizedShares = controller.addTokenizedShares(
            500, recipients, shares, string.concat(name(), " - Royalties Shares"), string.concat(symbol(), "RS")
        );

        // Optionally subscribe to Operator Filter Registry here
    }

    // Signal tokenizedShares as on chain royalties recipient
    function royaltyInfo(uint256, uint256 _salePrice) external view returns (address, uint256) {
        return (tokenizedShares, _salePrice * ROYALTIES_BPS / 10_000);
    }

    // Add support for EIP2981 interface
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // Override with custom logic
    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    // Override with custom logic
    function name() public pure override returns (string memory) {
        return "Collection Tokenized Royalties";
    }

    // Override with custom logic
    function symbol() public pure override returns (string memory) {
        return "CTR";
    }

    // Override with custom logic
    function tokenURI(uint256) public pure override returns (string memory) {
        return "";
    }
}
