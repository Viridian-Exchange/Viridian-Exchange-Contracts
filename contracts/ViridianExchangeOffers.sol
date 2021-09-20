pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./ViridianNFT.sol";
import "./ViridianPack.sol";

contract ViridianExchangeOffers is Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _offerIds;

    ViridianNFT vNFT;
    ViridianPack vPack;

    struct Offer {
        uint256 offerId;
        uint256[] toNftIds;
        uint256[] toPackIds;
        uint toAmt;
        uint256[] fromNftIds;
        uint256[] fromPackIds;
        uint fromAmt;
        address to;
        address from;
        bool isVEXT;
        bool pending;
    }

    mapping (address => Offer[]) userOffers;
    mapping (uint256 => Offer) offers;
    uint256[] private offerIds;
    mapping (uint256 => uint256) highestCardOffer;

    address public viridianNFT;
    address public viridianPack;
    address public ETH;
    address public viridianToken;

    constructor(address _viridianToken, address _viridianNFT, address _viridianPack) {
        require(address(_viridianToken) != address(0));
        //require(address(_ETH) != address(0));
        require(address(_viridianNFT) != address(0));
        require(address(_viridianPack) != address(0));

        viridianToken = _viridianToken;
        //address _ETH, ETH = _ETH;
        viridianNFT = _viridianNFT;
        viridianPack = _viridianPack;

        vNFT = ViridianNFT(_viridianNFT);
        vPack = ViridianPack(_viridianPack);
    }

    function getOffers() public view returns (uint256[] memory) {
        return offerIds;
    }

    function getOffersFromId(uint256 _offerId) public view returns (Offer memory) {
        return offers[_offerId];
    }

    function getOffersFromUser(address _userAddr) public view returns (Offer[] memory) {
        return userOffers[_userAddr];
    }

    function makeOffer(address _to, uint256[] memory _nftIds, uint256[] memory _packIds, uint256 _amount, uint256[] memory _recNftIds, uint256[] memory _recPackIds, uint256 _recAmount, bool isVEXT) public {
        require(_to != msg.sender);

        // if(!IERC721(viridianNFT).isApprovedForAll(msg.sender, address(this))) {
        //     IERC721(viridianNFT).setApprovalForAll(address(this), true);
        // }

        _offerIds.increment();
        uint256 _offerId = _offerIds.current();

        Offer memory newOffer = Offer(_offerId, _nftIds, _packIds, _amount, _recNftIds, _recPackIds, _recAmount, _to, msg.sender, isVEXT, true);
        
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
    
    function acceptOfferWithVEXT(uint256 _offerId) public {
        Offer storage curOffer = offers[_offerId];

        require(curOffer.to == msg.sender, "Only offered account can accept offer");

        for (uint i = 0; i < curOffer.toNftIds.length; i++) {
            require(IERC721(viridianNFT).ownerOf(curOffer.toNftIds[i]) == curOffer.from, "Offered account must own all requested NFTs");
        }

        for (uint i = 0; i < curOffer.fromNftIds.length; i++) {
            require(IERC721(viridianNFT).ownerOf(curOffer.fromNftIds[i]) == curOffer.to, "Offering account must own all offered NFTs");
        }

        for (uint i = 0; i < curOffer.toPackIds.length; i++) {
            require(IERC721(viridianPack).ownerOf(curOffer.toPackIds[i]) == curOffer.from, "Offered account must own all requested NFTs");
        }

        for (uint i = 0; i < curOffer.fromPackIds.length; i++) {
            require(IERC721(viridianPack).ownerOf(curOffer.fromPackIds[i]) == curOffer.to, "Offering account must own all offered NFTs");
        }
        

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

        for (uint i = 0; i < curOffer.toPackIds.length; i++) {
            //IERC721(viridianNFT).approve(curOffer.to, curOffer.fromNftIds[i]);
            IERC721(viridianPack).safeTransferFrom(curOffer.from, curOffer.to, curOffer.toPackIds[i]);
        }

        // Loop through all of the from items in the offer.
        for (uint i = 0; i < curOffer.fromPackIds.length; i++) {
            //IERC721(viridianNFT).approve(curOffer.to, curOffer.fromNftIds[i]);
            IERC721(viridianPack).safeTransferFrom(curOffer.to, curOffer.from, curOffer.fromPackIds[i]);
        }
    }

    //TODO: Maybe change this to MATIC?
    // function buyNFTWithETH(uint256 _listingId) public payable {
    //     Listing memory curListing = listings[_listingId];

    //     vNFT.unlistToken(curListing.tokenId);

    //     require(msg.sender.balance >= curListing.price, 'ViridianExchange: User does not have enough balance');
    //     address payable ownerWallet = payable(curListing.owner);

    //     require(msg.value == curListing.price, 'ViridianExchange: Incorrect amount paid to function');

    //     if(!IERC721(viridianNFT).isApprovedForAll(msg.sender, address(this))) {
    //         IERC721(viridianNFT).setApprovalForAll(address(this), true);
    //     }

    //     sendEther(ownerWallet);

    //     pullFromSaleOnBuy(_listingId);
        
    //     IERC721(viridianNFT).safeTransferFrom(curListing.owner, msg.sender, curListing.tokenId);
    // }

    // //TODO: Figure out how to send eth from "from" wallet to "to" wallet.
    //TODO: Figure out how to accept other cryptoCurrencies besides VEXT
    // function acceptOfferWithETH(uint256 _offerId) public payable {
    //     Offer storage curOffer = offers[_offerId];

    //     require(curOffer.to != msg.sender);

    //     // if(!IERC721(viridianNFT).isApprovedForAll(msg.sender, address(this))) {
    //     //     IERC721(viridianNFT).setApprovalForAll(address(this), true);
    //     // }

    //     address payable ownerWallet = payable(curOffer.from);

    //     sendEther(ownerWallet);

    //     cancelOffer(_offerId);
    // }
}