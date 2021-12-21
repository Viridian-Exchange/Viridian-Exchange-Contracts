pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

import "./ViridianNFT.sol";
import "./ViridianPack.sol";

contract ViridianExchangeOffers is BaseRelayRecipient, Ownable {

    //EVENTS
    event CreatedOffer(uint256 offerId, address wallet, bool created);
    event CancelledOffer(uint256 offerId, address wallet, bool cancelled);
    event AcceptedOffer(uint256 offerId, address wallet, bool accepted);


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
        address erc20Address;
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
    mapping (address => bool) public approvedTokens;

    constructor(address _erc20Token, address _viridianNFT, address _viridianPack) {//, address _forwarder) {
        require(address(_erc20Token) != address(0));
        require(address(_viridianNFT) != address(0));
        require(address(_viridianPack) != address(0));

        //_setTrustedForwarder(_forwarder);

        approvedTokens[_erc20Token] = true;
        //address _ETH, ETH = _ETH;
        viridianNFT = _viridianNFT;
        viridianPack = _viridianPack;

        vNFT = ViridianNFT(_viridianNFT);
        vPack = ViridianPack(_viridianPack);
    }

    string public override versionRecipient = "2.2.0";

    function setTrustedForwarder(address _forwarder) public onlyOwner() {
        _setTrustedForwarder(_forwarder);
    }

    function _msgSender() internal view override(Context, BaseRelayRecipient) returns (address sender) {
        sender = BaseRelayRecipient._msgSender();
    }

    function _msgData() internal view override(Context, BaseRelayRecipient) returns (bytes memory) {
        return BaseRelayRecipient._msgData();
    }

    function addERC20Token(address _erc20Address) public onlyOwner() {
        approvedTokens[_erc20Address] = true;
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

    function makeOffer(address payable _to, uint256[] memory _nftIds, uint256[] memory _packIds, uint256 _amount, uint256[] memory _recNftIds, uint256[] memory _recPackIds, uint256 _recAmount, address _erc20Address, uint256 _daysValid) public {
        require(approvedTokens[_erc20Address], "Must be listed price in approved token");
        require(_to != _msgSender());

        // if(!IERC721(viridianNFT).isApprovedForAll(_msgSender(), address(this))) {
        //     IERC721(viridianNFT).setApprovalForAll(address(this), true);
        // }

        _offerIds.increment();
        uint256 _offerId = _offerIds.current();

        uint256 endTime = block.timestamp + (_daysValid * 1 days);

        Offer memory newOffer = Offer(_offerId, _nftIds, _packIds, _amount, _recNftIds, _recPackIds, _recAmount, _to, payable(_msgSender()), _erc20Address, true, false, false, block.timestamp, endTime);
        
        userOffers[_to].push(newOffer);
        userOffers[_msgSender()].push(newOffer);
        offers[_offerId] = newOffer;

        doOfferingPartiesOwnContents(offers[_offerId]);
        offerIds.push(_offerId);

        emit CreatedOffer(_offerId, _msgSender(), true);
    }

    function removeOffer(Offer storage curOffer, Offer[] storage curUserOffers) private {
        for (uint i = 0; i < curUserOffers.length; i++) {
            Offer memory offer = curUserOffers[i];
            if (offer.offerId == curOffer.offerId) {
                curUserOffers[i] = curUserOffers[curUserOffers.length - 1];
                userOffers[curOffer.to] = curUserOffers;
                userOffers[curOffer.to].pop();
                break;
            }
        } 
    }
 
    function cancelOffer(uint256 _offerId) public {
        Offer storage curOffer = offers[_offerId];
        require(curOffer.from == _msgSender() || curOffer.to == _msgSender(), "Cannot be cancelled by non involved parties");
        require(!hasOfferExpired(_offerId), "Offer has expired");
        require(!curOffer.fromAccepted, "Cannot regular cancel when from party has accepted");
        require(!curOffer.toAccepted, "Cannot regular cancel when to party has accepted");

        Offer[] storage curUserOffers = userOffers[curOffer.to];
        Offer[] storage otherUserOffers = userOffers[curOffer.from];
        
        //TODO: Check who is cancelling and cancel that person's offers.

        // Remove offer from current user's offers
        removeOffer(curOffer, curUserOffers);

        // Remove offer from other user's offers
        removeOffer(curOffer, otherUserOffers);

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

        emit CancelledOffer(curOffer.offerId, _msgSender(), true);
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

    function getCurOffer(Offer storage curOffer, Offer[] storage curUserOffers) private view returns (Offer storage) {
        for (uint i = 0; i < curUserOffers.length; i++) {
            Offer memory offer = curUserOffers[i];
            if (offer.offerId == curOffer.offerId) {
                return curUserOffers[i]; //.pending = false;
            }
        }

        return curUserOffers[0];
    }
    
    function acceptOfferWithERC20(uint256 _offerId) public {
        Offer storage curOffer = offers[_offerId];

        require(curOffer.to == _msgSender(), "Only offered account can accept offer");
        require(!hasOfferExpired(_offerId), "Offer has expired");

        Offer[] storage curUserOffers = userOffers[curOffer.to];
        Offer[] storage otherUserOffers = userOffers[curOffer.from];

        // for (uint i = 0; i < curUserOffers.length; i++) {
        //     Offer memory offer = curUserOffers[i];
        //     if (offer.offerId == curOffer.offerId) {
        //         curUserOffers[i].pending = false;
        //         break;
        //     }
        // }

        Offer storage setOffer = getCurOffer(curOffer, curUserOffers);

        // for (uint i = 0; i < otherUserOffers.length; i++) {
        //     Offer memory offer = otherUserOffers[i];
        //     if (offer.offerId == curOffer.offerId) {
        //         otherUserOffers[i].pending = false;
        //         break;
        //     }
        // }

        Offer storage setOfferO = getCurOffer(curOffer, otherUserOffers);

        doOfferingPartiesOwnContents(curOffer);

        // if(!IERC721(viridianNFT).isApprovedForAll(_msgSender(), address(this))) {
        //     IERC721(viridianNFT).setApprovalForAll(address(this), true);
        // }

        IERC20(curOffer.erc20Address).transferFrom(curOffer.from, curOffer.to, curOffer.toAmt);
        IERC20(curOffer.erc20Address).transferFrom(curOffer.to, curOffer.from, curOffer.fromAmt);

        transferAllOfferContents(curOffer);

        curOffer.pending = false;
        setOffer.pending = false;
        setOfferO.pending = false;
        emit AcceptedOffer(_offerId, _msgSender(), true);
    }
}