// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IMarketplace {
    /// @dev getPrice() returns the price of an NFT from the FakeNFTMarketplace
    /// @return Returns the price in Wei for an NFT
    function getPrice() external view returns (uint256);

    /// @dev available() returns whether or not the given _tokenId has already been purchased
    /// @return Returns a boolean value - true if available, false if not
    function available(uint256 _tokenId) external view returns (bool);

    /// @dev purchase() purchases an NFT from the FakeNFTMarketplace
    /// @param _tokenId - the fake NFT tokenID to purchase
    function purchase(uint256 _tokenId) external payable;
}

interface IAgentsNFT {
     /// @dev balanceOf returns the number of NFTs owned by the given address
    /// @param owner - address to fetch number of NFTs for
    /// @return Returns the number of NFTs owned
    function balanceOf(address owner) external view returns (uint256);

    /// @dev tokenOfOwnerByIndex returns a tokenID at given index for owner
    /// @param owner - address to fetch the NFT TokenID for
    /// @param index - index of NFT in owned tokens array to fetch
    /// @return Returns the TokenID of the NFT
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

contract AgentsDAO is Ownable {
    /// @dev define what a proposal is
    struct Proposal {
        uint256 nftTokenId;
        uint256 deadline;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(uint256 => bool) voters;
    }

    /// @dev define possible options of vote
    enum Vote {
        YES,
        NO
    }

    /// @dev keep track of proposals
    mapping(uint256 => Proposal) public proposals;
    uint256 public numOfProposals;

    /// @dev initialise interfaces
    IMarketplace nftMarketplace;
    IAgentsNFT agentsNft;

    constructor (address _marketplace, address _agentsNFT) payable Ownable(msg.sender){
        nftMarketplace = IMarketplace(_marketplace);
        agentsNft = IAgentsNFT(_agentsNFT);
    }

    modifier nftHolderOnly(){
        require(agentsNft.balanceOf(msg.sender) > 0, "NOT_A_DAO_MEMBER");
        _;
    }

    modifier activeProposalOnly(uint256 proposalIndex){
        require(proposals[proposalIndex].deadline > block.timestamp, "DEADLINE_EXCEEDED");
        _;
    }

    modifier inactiveProposalOnly(uint256 proposalIndex){
        require(proposals[proposalIndex].deadline <= block.timestamp, "DEADLINE_NOT_EXCEEDED");
        require(proposals[proposalIndex].executed == false, "PROPOSAL_ALREADY_EXECUTED");
        _;
    }

    /// @dev createProposal() allows a member to create a proposal on the AgentsDAO
    /// @param _nftTokenId - tokenId of NFT to be purchased in the proposal from Marketplace
    /// @return returns the proposal index for the newly created proposal
    function createProposal(uint256 _nftTokenId) 
        external 
        nftHolderOnly 
        returns (uint256) 
    {
        require(nftMarketplace.available(_nftTokenId), "NFT_NOT_AVAILABLE");
        Proposal storage proposal  = proposals[numOfProposals];
        proposal.nftTokenId = _nftTokenId;
        proposal.deadline = block.timestamp + 5 minutes;

        numOfProposals++;

        return numOfProposals - 1;
    } 

    /// @dev voteOnProposal() allows a AgentsNFT holder to cast their vote on an active proposal
    /// @param proposalIndex - the index of the proposal to vote on in the proposals array
    /// @param vote - the type of vote they want to cast
    function voteOnProposal(uint256 proposalIndex, Vote vote) 
        external 
        nftHolderOnly 
        activeProposalOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];

        uint256 voterNftBalance = agentsNft.balanceOf(msg.sender);
        uint256 numVotes = 0;

        for(uint i = 0; i < voterNftBalance; i++){
            uint256 tokenId = agentsNft.tokenOfOwnerByIndex(msg.sender, i);
            if(proposal.voters[tokenId] == false){
                numVotes++;
                proposal.voters[tokenId] == true;
            }
        }

        require(numVotes > 0, "ALREADY_VOTED");

        if (vote == Vote.YES){
            proposal.yesVotes += numVotes;
        } else {
            proposal.noVotes += numVotes;
        }
    }

    /// @dev executeProposal() allows any AgentsNFT holder to execute a proposal after it's deadline has been exceeded
    /// @param proposalIndex - the index of the proposal to execute in the proposals array
    function executeProposal(uint256 proposalIndex) 
        external 
        nftHolderOnly 
        inactiveProposalOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];
        
        if(proposal.yesVotes > proposal.noVotes){
            uint256 nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
        }
        proposal.executed = true;
    }

    /// @dev withdrawEther allows the contract owner (deployer) to withdraw the ETH from the contract
    function withdrawEther() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "Nothing to withdraw, contract balance empty");
        (bool sent, ) = payable(owner()).call{value: amount}("");
        require(sent, "FAILED_TO_WITHDRAW_ETHER");
    }

    receive() external payable {}

    fallback() external payable {}
}