// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract XAgentsNFT is ERC721Enumerable {
    constructor() ERC721("CryptoDevs", "CD") {}

    /// @dev A public mint function anyone can call to get an NFT
    function mint() public {
        _safeMint(msg.sender, totalSupply());
    }
}