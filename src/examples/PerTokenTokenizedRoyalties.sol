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
 * @title PerTokenTokenizedRoyalties.
 * @author @eldief
 * @notice Example for per token TokenizedRoyalties.
 */
contract PerTokenTokenizedRoyalties is ERC721, IERC2981 {
    address public immutable owner;
    ISharesFactory public immutable factory;

    uint256 public constant ROYALTIES_BPS = 1_000; // 10%

    mapping(uint256 => address) public perTokenTokenizedShares;

    constructor(address factory_) {
        // Store contract owner
        owner = msg.sender;

        // Reference ISharesFactory implementation
        factory = ISharesFactory(factory_);

        // Optionally subscribe to Operator Filter here
    }

    // Mint TokenizedShares for each token minted, sending royalties rights 50% to minter, 50% to contract owner
    function mint(address to, uint256 tokenId) external {
        address[] memory recipients = new address[](2);
        recipients[0] = to;
        recipients[1] = owner;

        uint16[] memory shares = new uint16[](2);
        shares[0] = 5_000; // 50%
        shares[1] = 5_000; // 50%

        // Store ITokenizedShares proxy address
        perTokenTokenizedShares[tokenId] = factory.addTokenizedShares(recipients, shares);

        // Mint token
        _mint(to, tokenId);
    }

    // Signal tokenizedShares as on chain royalties recipient
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256) {
        address tokenizedShares = perTokenTokenizedShares[_tokenId];
        return (tokenizedShares, _salePrice * ROYALTIES_BPS / 10_000);
    }

    // Add support for EIP2981 interface
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
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
