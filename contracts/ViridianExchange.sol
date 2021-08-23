pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ViridianNFT.sol";

contract ViridianExchange is Ownable {

    struct Offer {
        uint256 offerId;
        uint256[] toNftIds;
        uint toAmt;
        uint256[] fromNftIds;
        uint fromAmt;
        address to;
        address from;
        bool isVEXT;
        bool pending;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _listingIds;
    Counters.Counter private _offerIds;

    //address vNFTContract = 
    
    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address owner;
        uint256 price;
        bool purchased;
        uint256 royalty;
        uint256 endTime;
        bool sold;
        bool isVEXT;
    }

    struct Collection {
        string description;
        uint256[] collectionNFTs;
    }

    //string[] public nftIds;
    mapping (address => Collection) displayCases;
    mapping (address => Listing[]) userListings;
    mapping (address => Offer[]) userOffers;
    mapping (uint256 => Offer) offers;
    mapping (uint256 => Listing) listings;
    address[] private userAddresses;
    uint256[] private listingIds;
    uint256[] private offerIds;

    address public viridianNFT;
    address public ETH;
    address public viridianToken;

    constructor(address _viridianToken, address _viridianNFT) {
        require(address(_viridianToken) != address(0)); 
        //require(address(_ETH) != address(0));
        require(address(_viridianNFT) != address(0));

        viridianToken = _viridianToken;
        //address _ETH, ETH = _ETH;
        viridianNFT = _viridianNFT;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getListings() public view returns (uint256[] memory) {
        return listingIds;
    }

    function getOffers() public view returns (uint256[] memory) {
        return offerIds;
    }

    function getListingFromId(uint256 _listingId) public view returns (Listing memory) {
        return listings[_listingId];
    }

    function getOffersFromId(uint256 _offerId) public view returns (Offer memory) {
        return offers[_offerId];
    }

    function getListingsFromUser(address _userAddr) public view returns (Listing[] memory) {
        return userListings[_userAddr];
    }

    function getOffersFromUser(address _userAddr) public view returns (Offer[] memory) {
        return userOffers[_userAddr];
    }

    function getNftOwner(uint256 _nftId) public view returns (address) {
        return IERC721(viridianNFT).ownerOf(_nftId);
    }

    function sendEther(address payable _to) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    function putUpForSale(uint256 _nftId, uint256 _price, uint256 _royalty, uint256 _endTime, bool _isVEXT) public payable {
        require(getNftOwner(_nftId) == msg.sender);

        // if(!IERC721(viridianNFT).isApprovedForAll(msg.sender, address(this))) {
        //     IERC721(viridianNFT).setApprovalForAll(address(this), true);
        // }

        _listingIds.increment();
        uint256 _listingId = _listingIds.current();
        Listing memory saleListing;
        saleListing.listingId = _listingId;
        saleListing.tokenId = _nftId;
        saleListing.owner = msg.sender;
        saleListing.price = _price;
        saleListing.purchased = false;
        saleListing.royalty = _royalty;
        saleListing.endTime = _endTime;
        saleListing.sold = false;
        saleListing.isVEXT = _isVEXT;

        //_listingId, _nftId, msg.sender, _price, false, 
        //                                    _royalty, _isAuction, _endTime, Bid(msg.sender, 0, _isVEXT), new Bid[](0), false, _isVEXT);
        userListings[msg.sender].push(saleListing);
        listings[_listingId] = saleListing;
        listingIds.push(saleListing.listingId);

        //ERC20(viridianToken).approve(address(this), _price);

        //IERC721(viridianNFT).approve(address(this), _nftId);
        //IERC721(viridianNFT).safeTransferFrom(msg.sender, address(this), _nftId);
    }
    
    function pullFromSale(uint256 _listingId) public payable {
        Listing memory curListing = listings[_listingId];
        require(curListing.owner == msg.sender);
        //IERC721(viridianNFT).safeTransferFrom(address(this), msg.sender, curListing.tokenId);
        Listing[] storage curUserListings = userListings[msg.sender];
        for (uint i = 0; i < curUserListings.length; i++) {
            Listing memory listing = curUserListings[i];
            if (listing.listingId == curListing.listingId) {
                curUserListings[i] = curUserListings[curUserListings.length - 1];
                userListings[msg.sender] = curUserListings;
                userListings[msg.sender].pop();
                break;
            }
        }

        for (uint256 i = 0; i < listingIds.length; i++) {
            uint256 listingId = listingIds[i];
            if (listingId == curListing.listingId) {
                listingIds[i] = listingIds[listingIds.length - 1];
                listingIds.pop();
                break;
            }
        }

        delete listings[_listingId];
    }

    function pullFromSaleOnBuy(uint256 _listingId) private {
        Listing memory curListing = listings[_listingId];
        //IERC721(viridianNFT).safeTransferFrom(address(this), msg.sender, curListing.tokenId);
        Listing[] storage curUserListings = userListings[curListing.owner];
        for (uint i = 0; i < curUserListings.length; i++) {
            Listing memory listing = curUserListings[i];
            if (listing.listingId == curListing.listingId) {
                curUserListings[i] = curUserListings[curUserListings.length - 1];
                userListings[curListing.owner] = curUserListings;
                userListings[curListing.owner].pop();
                break;
            }
        }

        for (uint256 i = 0; i < listingIds.length; i++) {
            uint256 listingId = listingIds[i];
            if (listingId == curListing.listingId) {
                listingIds[i] = listingIds[listingIds.length - 1];
                listingIds.pop();
                break;
            }
        }

        delete listings[_listingId];
    }

    function buyNFTWithETH(uint256 _listingId) public payable {
        Listing memory curListing = listings[_listingId];

        require(msg.sender.balance >= curListing.price, 'ViridianExchange: User does not have enough balance');
        address payable ownerWallet = payable(curListing.owner);

        require(msg.value == curListing.price, 'ViridianExchange: Incorrect amount paid to function');

        // if(!IERC721(viridianNFT).isApprovedForAll(msg.sender, address(this))) {
        //     IERC721(viridianNFT).setApprovalForAll(address(this), true);
        // }

        sendEther(ownerWallet);

        pullFromSaleOnBuy(_listingId);
        
        IERC721(viridianNFT).safeTransferFrom(curListing.owner, msg.sender, curListing.tokenId);
    }

    function buyNFTWithVEXT(uint256 _listingId) public payable {
        Listing memory curListing = listings[_listingId];

        require(IERC20(viridianToken).balanceOf(msg.sender) >= curListing.price, 'ViridianExchange: User does not have enough balance');

        // if(!IERC721(viridianNFT).isApprovedForAll(msg.sender, address(this))) {
        //     IERC721(viridianNFT).setApprovalForAll(address(this), true);
        // }

        // TODO: See if this implementation is preferrable
        // // Approve and transfer VEXT from sender to contract
        //IERC20(viridianToken).approve(msg.sender, curListing.price);
        //IERC20(viridianToken).transferFrom(msg.sender, address(this), curListing.price);

        // Approve and transfer VEXT from contract to listing owner
        //IERC20(viridianToken).approve(address(this), curListing.price);
        //IERC20(viridianToken).transfer(curListing.owner, curListing.price);

        // Approve and transfer NFT from sender to contract
        //IERC721(viridianNFT).approve(msg.sender, curListing.tokenId);

        // Approve and transfer NFT from contract to listing owner
        //IERC721(viridianNFT).approve(address(this), curListing.tokenId);
        //IERC721(viridianNFT).safeTransferFrom(address(this), msg.sender, curListing.tokenId);

        //IERC20(viridianToken).approve(msg.sender, curListing.price);
        IERC20(viridianToken).transferFrom(msg.sender, curListing.owner, curListing.price);

        IERC721(viridianNFT).approve(msg.sender, curListing.tokenId);
        IERC721(viridianNFT).safeTransferFrom(curListing.owner, msg.sender, curListing.tokenId);
        pullFromSaleOnBuy(_listingId);
    }

    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function makeOffer(address _to, uint256[] memory _nftIds, uint256 _amount, uint256[] memory _recNftIds, uint256 _recAmount, bool isVEXT) public {
        require(_to != msg.sender);

        // if(!IERC721(viridianNFT).isApprovedForAll(msg.sender, address(this))) {
        //     IERC721(viridianNFT).setApprovalForAll(address(this), true);
        // }

        _offerIds.increment();
        uint256 _offerId = _offerIds.current();

        Offer memory newOffer = Offer(_offerId, _nftIds, _amount, _recNftIds, _recAmount, _to, msg.sender, isVEXT, true);
        
        userOffers[_to].push(newOffer);
        offers[_offerId] = newOffer;
        offerIds.push(_offerId);
    }

    function cancelOffer(uint256 _offerId) public {
        Offer storage curOffer = offers[_offerId];
        require(curOffer.from == msg.sender || curOffer.to == msg.sender);
        Offer[] storage curUserOffers = userOffers[curOffer.to];
        
        //TODO: Check who is cancelling and cancel that person's offers.

        // Remove offer from current user's offers
        for (uint i = 0; i < curUserOffers.length; i++) {
            Offer memory offer = curUserOffers[i];
            if (offer.offerId == curOffer.offerId) {
                curUserOffers[i] = curUserOffers[curUserOffers.length - 1];
                userOffers[curOffer.to] = curUserOffers;
                userOffers[curOffer.to].pop();
                break;
            }
        } 

        // Remove offer id from global list of offer ids
        for (uint256 i = 0; i < offerIds.length; i++) {
            uint256 offerId = offerIds[i];
            if (offerId == curOffer.offerId) {
                offerIds[i] = offerIds[offerIds.length - 1];
                offerIds.pop();
                break;
            }
        }

        // Remove offer from global mapping of offers
        delete offers[_offerId];
    }

    //TODO: Figure out how to send eth from "from" wallet to "to" wallet.
    function acceptOfferWithETH(uint256 _offerId) public payable {
        Offer storage curOffer = offers[_offerId];

        require(curOffer.to != msg.sender);

        // if(!IERC721(viridianNFT).isApprovedForAll(msg.sender, address(this))) {
        //     IERC721(viridianNFT).setApprovalForAll(address(this), true);
        // }

        address payable ownerWallet = payable(curOffer.from);

        sendEther(ownerWallet);

        cancelOffer(_offerId);
    }

    function acceptOfferWithVEXT(uint256 _offerId) public {
        Offer storage curOffer = offers[_offerId];

        require(curOffer.to == msg.sender);

        // if(!IERC721(viridianNFT).isApprovedForAll(msg.sender, address(this))) {
        //     IERC721(viridianNFT).setApprovalForAll(address(this), true);
        // }

        IERC20(viridianToken).transferFrom(curOffer.from, curOffer.to, curOffer.toAmt);
        IERC20(viridianToken).transferFrom(curOffer.to, curOffer.from, curOffer.fromAmt);

        // Loop through all of the to items in the offer.
        for (uint i = 0; i < curOffer.toNftIds.length; i++) {
            //IERC721(viridianNFT).approve(curOffer.to, curOffer.fromNftIds[i]);
            IERC721(viridianNFT).safeTransferFrom(curOffer.from, curOffer.to, curOffer.toNftIds[i]);
        }

        // Loop through all of the from items in the offer.
        for (uint i = 0; i < curOffer.fromNftIds.length; i++) {
            //IERC721(viridianNFT).approve(curOffer.to, curOffer.fromNftIds[i]);
            IERC721(viridianNFT).safeTransferFrom(curOffer.to, curOffer.from, curOffer.fromNftIds[i]);
        }
    }
}