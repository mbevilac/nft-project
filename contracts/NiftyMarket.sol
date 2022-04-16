// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Nifty.sol";

/**
 * In a decentralized market you cannot use secret bids, because won't be secret
 * unless you can encrypt them somehow. Everything that appears in the contract
 * will be revealed to the users of the contract in the name of transaperency.
 */


contract NiftyMarket {

    Nifty private nifties;

    address private owner;

    address constant public NULL_ADDRESS = 0x0000000000000000000000000000000000000000;

    //mapping( uint256 => address ) private nft_ownership;

    mapping( uint256 => Bid [] ) private nft_bids; // will contain the history of bids for that token. Multiple Bid active for any tokenId

    mapping( uint256 => Offer[] ) private nft_offers; // will contain history of offers. Only one offer is active given a token id

    uint256 [] private nft_market_list; 

    //mapping( uint256 => bool ) private nft_market;

    uint256 private bid_fee = 2;

    struct Bid {

        address bidder;
        uint256 amount;
        uint256 tokenId;
        bool expired;
    }

    struct Offer {

        address seller;
        uint256 price;
        uint256 tokenId;
        bool expired;
    }

    constructor(address _niftyAddress) {
       
       nifties = Nifty(_niftyAddress); // use the contract that has been prev created

       owner = msg.sender; 

    }

    modifier onlyOwner() {
        require(owner == msg.sender, "only owner can call this function");
        _;
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
       // check if owner has a nifty
         address nifty_owner = nifties.ownerOf(_tokenId);

        require(nifty_owner == msg.sender, "the sender is not the owner of the specified token");
        _;

    }

    function setOwner(address _newOwner) external onlyOwner() {

        require(_newOwner != NULL_ADDRESS, "the new owner cannot be the 0x0 address");

        owner = _newOwner;
       
    }

    function enterMarket(uint256 _tokenId, uint256 _initial_price) external onlyTokenOwner(_tokenId) {
      

      _listToken(_tokenId, msg.sender, _initial_price);

    }

    function exitMarket(uint256 _tokenId) external onlyTokenOwner(_tokenId) {
      

      _delistToken(_tokenId);

    }

    function bid(uint256 _tokenId) payable external {

        // Check if the token is in the market
        address nft_owner = nifties.ownerOf(_tokenId);

        require(nft_owner != NULL_ADDRESS, "the token is not listed on this market");

        // a user can bid for multiple tokens
        Bid memory newBid;

        newBid.amount = msg.value; // this amount will be returned in case the bid doe not win
        newBid.bidder = msg.sender;
        newBid.tokenId = _tokenId;
        newBid.expired = false;

        nft_bids[_tokenId].push(newBid);

    }

    function closeAuction(uint256 _tokenId) external onlyTokenOwner(_tokenId) {

        // iterate through the bids and choose the highest
        Bid [] memory bids = nft_bids[_tokenId]; // retrieve all the bids for this token

        require(bids.length > 0, "no bids available for the selected token");

        Bid memory winner;

        for (uint i = 0; i < bids.length; i++){
            
            if( !bids[i].expired && bids[i].amount > winner.amount ){
               winner = bids[i]; // update winner
            }
            
            
        }

        // return amount to participants but the winner
        for (uint i = 0; i < bids.length; i++){
            
            if( !bids[i].expired && bids[i].bidder != winner.bidder ){
               // return amount
               uint256 fee = (bids[i].amount * bid_fee)/100;
               payable(bids[i].bidder).transfer(bids[i].amount - fee); 
            }

            // set the bid as expired
            bids[i].expired = true;
            
        }
        // transfer token to winner
        nifties.transferFrom(msg.sender, winner.bidder, _tokenId);


        assert(nifties.ownerOf(_tokenId) == winner.bidder);

        // delist token from market
        _delistToken(_tokenId);

    }

    function cancelBid(uint256 _tokenId) external {

        // iterate through the bids
        Bid [] memory bids = nft_bids[_tokenId];

        require( bids.length > 0, "no bids available for the selected token");

        for (uint i = 0; i < bids.length; i++){
            
            // check if bidder is sender and the bid did not expire
            if( bids[i].bidder == msg.sender && !bids[i].expired ){
               
               // return the money
               uint256 fee = (bids[i].amount * bid_fee)/100;
               payable(bids[i].bidder).transfer(bids[i].amount - fee); 
               bids[i].expired = true;
            }
            
        }


    }

    function _listToken(uint256 _tokenId, address _user, uint256 _initial_price) internal {

      nft_market_list.push(_tokenId); // do I need it?

      Offer memory offer;

      offer.expired = false;
      offer.price = _initial_price;
      offer.seller = _user;
      offer.tokenId = _tokenId;

      nft_offers[_tokenId].push(offer);

    }

    function _delistToken(uint256 _tokenId) internal {
      
      Offer [] memory _offers = nft_offers[_tokenId];

      // remove all the active offers for this token on the market
      for (uint i = 0; i < _offers.length; i++){
          
          if( _offers[i].tokenId == _tokenId ){
              _offers[i].expired = true;
          }
        
      }


      uint index = 0;

      for (uint i = 0; i < nft_market_list.length; i++){
          
          if( nft_market_list[i] == _tokenId ){
              index = i;
          }
        
      }

      delete nft_market_list[index];

    }

    function getListedTokens() external view returns(uint256 [] memory) {

        return nft_market_list;

    }


 

}

