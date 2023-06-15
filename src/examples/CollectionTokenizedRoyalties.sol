// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../SharesFactory.sol";
import "../ERC1155TokenizedShares.sol";
import "./ERC1155TokenizedSharesMock.sol";
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
        // Reference ISharesFactory implementation
        ISharesFactory factory = ISharesFactory(factory_);

        // Create new ITokenizedShares with no keeperShares and defaultImplementation
        tokenizedShares = factory.addTokenizedShares(recipients, shares);

        // Optionally subscribe to Operator Filter here
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
        return "";
    }

    // Override with custom logic
    function symbol() public pure override returns (string memory) {
        return "";
    }

    // Override with custom logic
    function tokenURI(uint256) public pure override returns (string memory) {
        return "";
    }
}
