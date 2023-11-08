// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
contract tokenerc721 is ERC721, Ownable, ERC2981 {
    constructor()
        ERC721("MyToken", "MTK")
    {}

    function safeMint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }

    function SetDefaultRoyalty(address receiver, uint96 fee) external onlyOwner(){
        _setDefaultRoyalty(receiver, fee);
    }

    function SetTokenRoyalty(uint256 tokenId, address receiver, uint96 fee)  external onlyOwner(){
        _setTokenRoyalty(tokenId, receiver, fee);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}