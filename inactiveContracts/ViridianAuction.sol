pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ViridianNFT.sol";
import "./ViridianExchange.sol";

abstract contract ViridianAuction is ViridianExchange {
    struct Auction {
        Bid largestBid;
        uint256[] bidIds;
    }

    struct Bid {
        address owner;
        uint256 amount;
        bool isVEXT;
    }

    Counters.Counter private _bidIds;
    mapping (uint256 => Bid) bids;


    // function bidOnAuctionWithVEXT(uint256 _listingId, uint256 _amount) public override {
    //     Listing storage curListing = listings[_listingId];

    //     require(curListing.isAuction, 'ViridianExchange: Cannot bid, current listing is not auction');
    //     require(curListing.largestBid.amount < _amount, 'ViridianExchagne: Bid must be larger than current largest bid');

    //     Bid memory newBid = Bid(msg.sender, _amount, true);

    //     super._bidIds.increment();
    //     uint256 _bidId = super._offerIds.current();

    //     curListing.bidIds.push(_bidId);
    //     bids[_bidId] = newBid;
    //     curListing.largestBid = newBid;
    // }

    // function bidOnAuctionWithETH(uint256 _listingId, uint256 _amount) public override {
    //     Listing storage curListing = listings[_listingId];

    //     require(curListing.isAuction, 'ViridianExchange: Cannot bid, current listing is not auction');
    //     require(curListing.largestBid.amount < _amount, 'ViridianExchagne: Bid must be larger than current largest bid');

    //     Bid memory newBid = Bid(msg.sender, _amount, false);

    //     super._bidIds.increment();
    //     uint256 _bidId = super._offerIds.current();

    //     curListing.bidIds.push(_bidId);
    //     bids[_bidId] = newBid;
    //     curListing.largestBid = newBid;
    // }

    // function bidOnAuctionWithVEXT(uint256 _listingId, uint256 _amount) public {
    //     Listing storage curListing = listings[_listingId];

    //     require(curListing.isAuction, 'ViridianExchange: Cannot bid, current listing is not auction');
    //     require(curListing.largestBid.amount < _amount, 'ViridianExchagne: Bid must be larger than current largest bid');

    //     Bid memory newBid = Bid(msg.sender, _amount, true);

    //     _bidIds.increment();
    //     uint256 _bidId = _offerIds.current();

    //     curListing.bidIds.push(_bidId);
    //     bids[_bidId] = newBid;
    //     curListing.largestBid = newBid;
    // }

    // function bidOnAuctionWithETH(uint256 _listingId, uint256 _amount) public {
    //     Listing storage curListing = listings[_listingId];

    //     require(curListing.isAuction, 'ViridianExchange: Cannot bid, current listing is not auction');
    //     require(curListing.largestBid.amount < _amount, 'ViridianExchagne: Bid must be larger than current largest bid');

    //     Bid memory newBid = Bid(msg.sender, _amount, false);

    //     _bidIds.increment();
    //     uint256 _bidId = _offerIds.current();

    //     curListing.bidIds.push(_bidId);
    //     bids[_bidId] = newBid;
    //     curListing.largestBid = newBid;
    // }
}