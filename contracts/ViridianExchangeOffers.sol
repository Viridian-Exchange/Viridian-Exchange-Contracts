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
        address payable to;
        address payable from;
        bool isVEXT;
        bool pending;
        bool toAccepted;
        bool fromAccepted;
        uint256 startTime;
        uint256 endTime;
    }

    mapping (address => Offer[]) userOffers;
    mapping (uint256 => Offer) offers;
    uint256[] private offerIds;
    mapping (uint256 => uint256) highestCardOffer;

    address public viridianNFT;
    address public viridianPack;
    address public viridianToken;

    constructor(address _viridianToken, address _viridianNFT, address _viridianPack) {
        require(address(_viridianToken) != address(0));
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

    function hasOfferExpired(uint256 _offerId) public view returns (bool) {
        Offer storage curOffer = offers[_offerId];

        // Always return false if the current offer is pending final approval
        if (curOffer.toAccepted && !curOffer.fromAccepted) {
            return false;
        }

        if (!curOffer.pending) {
            return true;
        }
        else {
            return curOffer.endTime < block.timestamp;
        }
    }

    function makeOffer(address payable _to, uint256[] memory _nftIds, uint256[] memory _packIds, uint256 _amount, uint256[] memory _recNftIds, uint256[] memory _recPackIds, uint256 _recAmount, bool isVEXT, uint256 _daysValid) public {
        require(_to != msg.sender);

        // if(!IERC721(viridianNFT).isApprovedForAll(msg.sender, address(this))) {
        //     IERC721(viridianNFT).setApprovalForAll(address(this), true);
        // }

        _offerIds.increment();
        uint256 _offerId = _offerIds.current();

        uint256 endTime = block.timestamp + (_daysValid * 1 days);

        Offer memory newOffer = Offer(_offerId, _nftIds, _packIds, _amount, _recNftIds, _recPackIds, _recAmount, _to, payable(msg.sender), isVEXT, true, false, false, block.timestamp, endTime);
        
        userOffers[_to].push(newOffer);
        userOffers[msg.sender].push(newOffer);
        offers[_offerId] = newOffer;
        offerIds.push(_offerId);
    }

    function cancelOffer(uint256 _offerId) public {
        Offer storage curOffer = offers[_offerId];
        require(curOffer.from == msg.sender || curOffer.to == msg.sender);
        require(!hasOfferExpired(_offerId), "Offer has expired");
        require(!curOffer.fromAccepted, "Cannot regular cancel when from party has accepted");
        require(!curOffer.toAccepted, "Cannot regular cancel when to party has accepted");

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

    function cancelAcceptedETHOffer(uint256 _offerId) public payable {
        Offer storage curOffer = offers[_offerId];
        require(curOffer.from == msg.sender || curOffer.to == msg.sender);
        require(!hasOfferExpired(_offerId), "Offer has expired");
        require(!curOffer.fromAccepted, "Cannot regular cancel when from party has accepted");
        require(curOffer.toAccepted, "Cannot regular cancel when to party has accepted");
        Offer[] storage curUserOffers = userOffers[curOffer.to];
        
        //TODO: Check who is cancelling and cancel that person's offers.

        //Send money back to acceptor
        require(curOffer.fromAmt == msg.value, "Must send correct amount of ETH to owner of listing");
            curOffer.to.transfer(curOffer.fromAmt);

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

    function doOfferingPartiesOwnContents(Offer storage _curOffer) private view {
        for (uint i = 0; i < _curOffer.toNftIds.length; i++) {
            require(IERC721(viridianNFT).ownerOf(_curOffer.toNftIds[i]) == _curOffer.from, "Offered account must own all requested NFTs");
        }

        for (uint i = 0; i < _curOffer.fromNftIds.length; i++) {
            require(IERC721(viridianNFT).ownerOf(_curOffer.fromNftIds[i]) == _curOffer.to, "Offering account must own all offered NFTs");
        }

        for (uint i = 0; i < _curOffer.toPackIds.length; i++) {
            require(IERC721(viridianPack).ownerOf(_curOffer.toPackIds[i]) == _curOffer.from, "Offered account must own all requested NFTs");
        }

        for (uint i = 0; i < _curOffer.fromPackIds.length; i++) {
            require(IERC721(viridianPack).ownerOf(_curOffer.fromPackIds[i]) == _curOffer.to, "Offering account must own all offered NFTs");
        }
    }

    function transferAllOfferContents(Offer storage _curOffer) private {
        // Loop through all of the to items in the offer.
        for (uint i = 0; i < _curOffer.toNftIds.length; i++) {
            //IERC721(viridianNFT).approve(curOffer.to, curOffer.fromNftIds[i]);
            IERC721(viridianNFT).safeTransferFrom(_curOffer.from, _curOffer.to, _curOffer.toNftIds[i]);
        }

        // Loop through all of the from items in the offer.
        for (uint i = 0; i < _curOffer.fromNftIds.length; i++) {
            //IERC721(viridianNFT).approve(curOffer.to, curOffer.fromNftIds[i]);
            IERC721(viridianNFT).safeTransferFrom(_curOffer.to, _curOffer.from, _curOffer.fromNftIds[i]);
        }

        for (uint i = 0; i < _curOffer.toPackIds.length; i++) {
            //IERC721(viridianNFT).approve(curOffer.to, curOffer.fromNftIds[i]);
            IERC721(viridianPack).safeTransferFrom(_curOffer.from, _curOffer.to, _curOffer.toPackIds[i]);
        }

        // Loop through all of the from items in the offer.
        for (uint i = 0; i < _curOffer.fromPackIds.length; i++) {
            //IERC721(viridianNFT).approve(curOffer.to, curOffer.fromNftIds[i]);
            IERC721(viridianPack).safeTransferFrom(_curOffer.to, _curOffer.from, _curOffer.fromPackIds[i]);
        }
    }
    
    function acceptOfferWithVEXT(uint256 _offerId) public {
        Offer storage curOffer = offers[_offerId];

        require(curOffer.to == msg.sender, "Only offered account can accept offer");
        require(!hasOfferExpired(_offerId), "Offer has expired");

        curOffer.pending = false;

        doOfferingPartiesOwnContents(curOffer);

        // if(!IERC721(viridianNFT).isApprovedForAll(msg.sender, address(this))) {
        //     IERC721(viridianNFT).setApprovalForAll(address(this), true);
        // }

        IERC20(viridianToken).transferFrom(curOffer.from, curOffer.to, curOffer.toAmt);
        IERC20(viridianToken).transferFrom(curOffer.to, curOffer.from, curOffer.fromAmt);

        transferAllOfferContents(curOffer);
    }

    function acceptOfferWithETH(uint256 _offerId) public payable {
        Offer storage curOffer = offers[_offerId];

        require(curOffer.to == msg.sender, "Only offered account can accept offer");
        require(!hasOfferExpired(_offerId), "Offer has expired");
        require(curOffer.fromAmt == msg.value, "Must send correct amount of ETH to the smart contract for holding");
        require(!curOffer.fromAccepted, "Offer is already accepted and approved");
        require(!curOffer.toAccepted, "Offered party has already accepted, wait for the original offerer to make final approval");

        //curOffer.pending = true;
        curOffer.toAccepted = true;

        doOfferingPartiesOwnContents(curOffer);

        // if(!IERC721(viridianNFT).isApprovedForAll(msg.sender, address(this))) {
        //     IERC721(viridianNFT).setApprovalForAll(address(this), true);
        // }

        // IERC20(viridianToken).transferFrom(curOffer.from, curOffer.to, curOffer.toAmt);
        // IERC20(viridianToken).transferFrom(curOffer.to, curOffer.from, curOffer.fromAmt);

        // // Loop through all of the to items in the offer.
        // for (uint i = 0; i < curOffer.toNftIds.length; i++) {
        //     //IERC721(viridianNFT).approve(curOffer.to, curOffer.fromNftIds[i]);
        //     IERC721(viridianNFT).safeTransferFrom(curOffer.from, curOffer.to, curOffer.toNftIds[i]);
        // }

        // // Loop through all of the from items in the offer.
        // for (uint i = 0; i < curOffer.fromNftIds.length; i++) {
        //     //IERC721(viridianNFT).approve(curOffer.to, curOffer.fromNftIds[i]);
        //     IERC721(viridianNFT).safeTransferFrom(curOffer.to, curOffer.from, curOffer.fromNftIds[i]);
        // }

        // for (uint i = 0; i < curOffer.toPackIds.length; i++) {
        //     //IERC721(viridianNFT).approve(curOffer.to, curOffer.fromNftIds[i]);
        //     IERC721(viridianPack).safeTransferFrom(curOffer.from, curOffer.to, curOffer.toPackIds[i]);
        // }

        // // Loop through all of the from items in the offer.
        // for (uint i = 0; i < curOffer.fromPackIds.length; i++) {
        //     //IERC721(viridianNFT).approve(curOffer.to, curOffer.fromNftIds[i]);
        //     IERC721(viridianPack).safeTransferFrom(curOffer.to, curOffer.from, curOffer.fromPackIds[i]);
        // }
    }

    function finalApprovalWithETH(uint256 _offerId) public payable {
        Offer storage curOffer = offers[_offerId];

        require(curOffer.from == msg.sender, "Only offering account can make final approval");
        require(curOffer.toAccepted, "Offered party must accept before final approval");
        require(!curOffer.fromAccepted, "Offering party has already accepted");
        require(!hasOfferExpired(_offerId), "Offer has expired");

        curOffer.pending = false;
        curOffer.fromAccepted = true;

        doOfferingPartiesOwnContents(curOffer);

        // if(!IERC721(viridianNFT).isApprovedForAll(msg.sender, address(this))) {
        //     IERC721(viridianNFT).setApprovalForAll(address(this), true);
        // }

        // Transfer held ETH in smart contract to caller.
        curOffer.from.transfer(curOffer.fromAmt);
        
        // Transfer to ETH to offered party.
        require(curOffer.toAmt == msg.value, "Must send correct amount of ETH to the offered party");
        curOffer.to.transfer(msg.value);


        // IERC20(viridianToken).transferFrom(curOffer.from, curOffer.to, curOffer.toAmt);
        // IERC20(viridianToken).transferFrom(curOffer.to, curOffer.from, curOffer.fromAmt);

        // Loop through all of the to items in the offer.
        transferAllOfferContents(curOffer);
    }

    receive() external payable {}
}