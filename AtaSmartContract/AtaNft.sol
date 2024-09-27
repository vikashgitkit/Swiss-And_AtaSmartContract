// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArcaneTowerAscendent is ERC721URIStorage, Ownable {
    uint256 public tokenCounter;

    constructor(address initialOwner) ERC721("Arcane", "ATA") Ownable(initialOwner) {
        tokenCounter = 0;
    }

    function createCollectible(string memory tokenURI) public onlyOwner returns (uint256) {
        uint256 newItemId = tokenCounter;
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        tokenCounter++;
        return newItemId;
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI) public onlyOwner {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _setTokenURI(tokenId, tokenURI);
    }

    function mintMultipleCollectibles(string[] memory tokenURIs) public onlyOwner {
        for (uint256 i = 0; i < tokenURIs.length; i++) {
            createCollectible(tokenURIs[i]);
        }
    }

    function burn(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "ERC721: burn of nonexistent token");
        _burn(tokenId);
    }

    // Add the _exists function
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
}