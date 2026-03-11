// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SimpleMarketplace
 * @dev Facilitates buying and selling of NFTs with Reentrancy protection.
 */
contract SimpleMarketplace is ReentrancyGuard, Ownable {
    
    struct Listing {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
        bool active;
    }

    mapping(uint256 => Listing) public listings;
    uint256 public listingCount;

    event Listed(uint256 indexed listingId, address indexed seller, uint256 price);
    event Sold(uint256 indexed listingId, address indexed buyer, uint256 price);

    constructor() Ownable(msg.sender) {}

    function listNft(address _nftAddress, uint256 _tokenId, uint256 _price) external {
        require(_price > 0, "Price must be greater than zero");
        IERC721 nft = IERC721(_nftAddress);
        require(nft.ownerOf(_tokenId) == msg.sender, "Not the owner");
        require(nft.isApprovedForAll(msg.sender, address(this)), "Marketplace not approved");

        listingCount++;
        listings[listingCount] = Listing(msg.sender, _nftAddress, _tokenId, _price, true);

        emit Listed(listingCount, msg.sender, _price);
    }

    function buyNft(uint256 _listingId) external payable nonReentrant {
        Listing storage listing = listings[_listingId];
        require(listing.active, "Listing not active");
        require(msg.value >= listing.price, "Insufficient funds");

        listing.active = false;
        
        IERC721(listing.nftAddress).safeTransferFrom(listing.seller, msg.sender, listing.tokenId);
        payable(listing.seller).transfer(msg.value);

        emit Sold(_listingId, msg.sender, listing.price);
    }
}
