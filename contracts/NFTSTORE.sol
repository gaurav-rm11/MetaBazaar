// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFTSTORE is ERC721URIStorage {
    address payable public marketplaceOwner;
    uint256 public listingFeePercent = 20;
    uint256 private currentTokenId;
    uint256 private totalItemsSold;

    struct nftListing {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
    }

    mapping (uint256 => nftListing) private tokenIdToListing;

    modifier onlyMarketplaceOwner {
        require(msg.sender == marketplaceOwner,"Only Owner Can Access This");
        _;
    }

    constructor() ERC721("NFTSTORE", "NFS") {
        marketplaceOwner = payable(msg.sender);
    }

    // Helper functions
    function updateListingFeePercent(uint256 _listingFeePercent) public onlyMarketplaceOwner {
        listingFeePercent = _listingFeePercent;
    }

    function getListingFeePercent() public view returns (uint256) {
        return listingFeePercent;
    }

    function getCurrentTokenId() public view returns (uint256) {
        return currentTokenId;
    }

    function getNFTListing(uint256 _tokenId) public view returns (nftListing memory) {
        return tokenIdToListing[_tokenId];
    }

    // Main functions
    function createNftListing(uint256 _tokenId, uint256 _price) private {
        tokenIdToListing[_tokenId] = nftListing({
            tokenId: _tokenId,
            owner: payable(msg.sender),
            seller: payable(msg.sender),
            price: _price
        });
    }

    function createToken(string memory _tokenURI, uint256 _price) public returns (uint256) {
        require(_price > 0, "Price must be greater than zero");

        currentTokenId++;
        uint256 newTokenId = currentTokenId;
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);

        createNftListing(newTokenId, _price);

        return newTokenId;
    }

    function sellNFT(uint256 tokenId) public payable {
        nftListing storage listing = tokenIdToListing[tokenId];
        uint256 price = listing.price;
        address payable seller = listing.seller;

        require(msg.value == price, "Please pay the asking price");
        listing.seller = payable(msg.sender);
        totalItemsSold++;

        _transfer(listing.owner, msg.sender, tokenId);

        uint256 listingFee = (price * listingFeePercent) / 100;
        marketplaceOwner.transfer(listingFee);
        seller.transfer(msg.value - listingFee);
    }

    function getAllListedNFTs() public view returns (nftListing[] memory) {
        uint256 totalNFTCount = currentTokenId;
        nftListing[] memory listedNFTs = new nftListing[](totalNFTCount);
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalNFTCount; i++) {
            uint256 tokenId = i + 1;
            nftListing storage listing = tokenIdToListing[tokenId];
            listedNFTs[currentIndex] = listing;
            currentIndex += 1;
        }

        return listedNFTs;
    }

    function getMyNFTs() public view returns (nftListing[] memory) {
        uint256 totalNFTCount = currentTokenId;
        uint256 myNFTCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalNFTCount; i++) {
            if (tokenIdToListing[i + 1].owner == msg.sender || tokenIdToListing[i + 1].seller == msg.sender) {
                myNFTCount++;
            }
        }

        nftListing[] memory myNFTs = new nftListing[](myNFTCount);
        for (uint256 i = 0; i < totalNFTCount; i++) {
            if (tokenIdToListing[i + 1].owner == msg.sender || tokenIdToListing[i + 1].seller == msg.sender) {
                uint256 tokenId = i + 1;
                nftListing storage listing = tokenIdToListing[tokenId];
                myNFTs[currentIndex] = listing;
                currentIndex++;
            }
        }

        return myNFTs;
    }
}
