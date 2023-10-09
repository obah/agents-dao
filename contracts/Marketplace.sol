// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Marketplace {
    /// @dev keep track of tokenIds and owner addresses
    mapping(uint256 => address) public tokens;

    /// @dev set the purchase price of nft in the marketplace
    uint256 nftPrice = 0.01 ether;

    /// @dev purchase() accepts ETH and marks the owner of the given tokenId as the caller address
    /// @param _tokenId - the nft tokenId to be purchased
    function purchase(uint256 _tokenId) external payable {
        require(msg.value == nftPrice, "This NFT cost 0.01 ether");
        tokens[_tokenId] = msg.sender;
    }

    /// @dev getPrice() returns the price of one NFT
    function getPrice() external view returns (uint256){
        return nftPrice;
    }

    /// @dev available() checks if a tokenId has been sold or not
    /// @param _tokenId - the token to be checked
    /// @return returns boolean value indicating availability of _tokenId
    function available(uint256 _tokenId) external view returns (bool){
        if(tokens[_tokenId] == address(0)){
            return true;
        }
        return false;
    }
}