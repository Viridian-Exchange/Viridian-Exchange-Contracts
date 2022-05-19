// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

import "./ViridianGenesisNFT.sol";

/**
 * Exchange contract that helps facilitate the bartering and offering of Viridian NFTs and ERC20 tokens between users.
 * Will support cross-chain offers whether the NFT or listing is on that chain or not.
 */
contract ViridianExchangeOffers is BaseRelayRecipient, Ownable {

    // Events to assist offer creating, accepting, and cancelling visuals on front-end.
    event CreatedOffer(uint256 offerId, address wallet, bool created);
    event CreatedCounterOffer(uint256 offerId, uint256 oldOfferId, address wallet, bool created);
    event CancelledOffer(uint256 offerId, address wallet, bool cancelled);
    event AcceptedOffer(uint256 offerId, address wallet, bool accepted);

    // Incrementing counter for offer Ids
    using Counters for Counters.Counter;
    Counters.Counter private _offerIds;

    // Viridian Genesis NFT instance
    ViridianGenesisNFT vNFT;

    // Struct with all information for an offer
    struct Offer {
        uint256 offerId;
        uint256[] toNftIds;
        uint toAmt;
        uint256[] fromNftIds;
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

    // All offers that an individual user has made (Maybe remove for gas optimization on Ethereum)
    mapping (address => Offer[]) userOffers;
    // All offers on the exchange
    mapping (uint256 => Offer) offers;
    // All offer ids on the site (Maybe remove for gas optimization)
    uint256[] private offerIds;
    // Highest current offer for an NFT on the site
    mapping (uint256 => uint256) highestNFTOffer;
    // All tokens that are not allowed to be offered on the platform
    mapping (uint256 => bool) tokenIdBlacklist;

    // Treasury address where royalty payments are sent to
    address private treasuryAddress;
    // Base royalty amount for site transactions
    uint256 private baseRoyalty;
    // Royalty for users who are recieving promotional rates
    uint256 private whitelistRoyalty;

    // The current address for the Viridian NFT Contract
    address public viridianNFT;

    // All approved ERC20 tokens that can be used on the site.
    mapping (address => bool) public approvedTokens;

    /**
     * @dev Set the default ERC20Token address, Viridian NFT address, forwarder for gasless, and treasury for royalty payments.
     */
    constructor(address _erc20Token, address _viridianNFT, address _forwarder, address _treasuryAddress) {
        require(address(_erc20Token) != address(0));
        require(address(_viridianNFT) != address(0));
        _setTrustedForwarder(_forwarder);

        treasuryAddress = _treasuryAddress;
        baseRoyalty = 5;
        whitelistRoyalty = 0;

        approvedTokens[_erc20Token] = true;
        viridianNFT = _viridianNFT;

        vNFT = ViridianGenesisNFT(_viridianNFT);
    }

    string public override versionRecipient = "2.2.0";

    /**
     * @dev Owner can change the trusted forwarder used for gasless.
     */
    function setTrustedForwarder(address _forwarder) public onlyOwner() {
        _setTrustedForwarder(_forwarder);
    }

    /**
     * @dev Owner can set a new default royalty value for the exchange.
     */
    function setRoyalty(uint256 _newRoyalty) public onlyOwner() {
        baseRoyalty = _newRoyalty;
    }

    /**
     * @dev Owner can set a new promotional royalty value for the exchange.
     */
    function setWhitelistRoyalty(uint256 _newRoyalty) public onlyOwner() {
        baseRoyalty = _newRoyalty;
    }

    /**
     * @dev Replaces msg.sender for gasless support.
     */
    function _msgSender() internal view override(Context, BaseRelayRecipient) returns (address sender) {
        sender = BaseRelayRecipient._msgSender();
    }

    /**
     * @dev Replaces msg.data for gasless support.
     */
    function _msgData() internal view override(Context, BaseRelayRecipient) returns (bytes memory) {
        return BaseRelayRecipient._msgData();
    }

    /**
     * @dev Owner can add support for a new ERC20 token on the exchange.
     */
    function addERC20Token(address _erc20Address) public onlyOwner() {
        approvedTokens[_erc20Address] = true;
    }

    /**
     * @dev Owner can remove support for an ERC20 token on the exchange.
     */
    function removeERC20Token(address _erc20Address) public onlyOwner() {
        approvedTokens[_erc20Address] = false;
    }

    /**
     * @dev Returns the Ids of all offers on the exchange.
     */
    function getOffers() public view returns (uint256[] memory) {
        return offerIds;
    }

    /**
     * @dev Returns the offer struct associated with the given Id.
     */
    function getOffersFromId(uint256 _offerId) public view returns (Offer memory) {
        return offers[_offerId];
    }

    /**
     * @dev Returns all offers made by the given address.
     */
    function getOffersFromUser(address _userAddr) public view returns (Offer[] memory) {
        return userOffers[_userAddr];
    }

    /**
     * @dev Returns whether an offer has expired.
     */
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

    /**
     * @dev Make an offer to a user for a combination of their ERC20 tokens and NFTS for a combination of your ERC20 tokens and NFTs.
     */
    function makeOffer(address payable _to, uint256[] memory _nftIds, uint256 _amount, uint256[] memory _recNftIds, uint256 _recAmount, address _erc20Address, uint256 _daysValid, bool _isCounterOffer, uint256 _oldOfferId) public {
        require(approvedTokens[_erc20Address], "Must be listed price in approved token");
        require(_to != msg.sender, "Cannot send an offer to yourself");

        // Create offer struct with all the inputted specifications
        _offerIds.increment();
        uint256 _offerId = _offerIds.current();

        uint256 endTime = block.timestamp + (_daysValid * 1 days);

        Offer memory newOffer = Offer(_offerId, _nftIds, _amount, _recNftIds, _recAmount, _to, payable(msg.sender), _erc20Address, true, false, false, block.timestamp, endTime);
        
        userOffers[_to].push(newOffer);
        userOffers[msg.sender].push(newOffer);
        offers[_offerId] = newOffer;

        doOfferingPartiesOwnContents(offers[_offerId]);
        offerIds.push(_offerId);

        // Emit a different event if it is a counter offer or not for front-end handling.
        if (_isCounterOffer) {
            emit CreatedCounterOffer(_offerId, _oldOfferId, msg.sender, true);
        }
        else {
            emit CreatedOffer(_offerId, msg.sender, true);
        }
    }

    /**
     * @dev Remove an offer from the exchange.
     */
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
 
    /**
     * @dev Cancel an offer if you are the party making the offer or are the party recieveing the offer.
     */
    function cancelOffer(uint256 _offerId) public {
        Offer storage curOffer = offers[_offerId];
        require(curOffer.from == msg.sender || curOffer.to == msg.sender, "Cannot be cancelled by non involved parties");
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

        emit CancelledOffer(curOffer.offerId, msg.sender, true);
    }

    /**
     * @dev Assure that all the same parties own the offer contents from when the offer was originally made.
     */
    function doOfferingPartiesOwnContents(Offer storage _curOffer) private view {
        for (uint i = 0; i < _curOffer.toNftIds.length; i++) {
            require(IERC721(viridianNFT).ownerOf(_curOffer.toNftIds[i]) == _curOffer.from, "Offered account must own all requested NFTs");
        }

        for (uint i = 0; i < _curOffer.fromNftIds.length; i++) {
            require(IERC721(viridianNFT).ownerOf(_curOffer.fromNftIds[i]) == _curOffer.to, "Offering account must own all offered NFTs");
        }
    }

    /**
     * @dev Transfer all offer contents to their intended destinations.
     */
    function transferAllOfferContents(Offer storage _curOffer) private {
        // Loop through all of the to items in the offer.
        for (uint i = 0; i < _curOffer.toNftIds.length; i++) {
            //IERC721(viridianNFT).approve(curOffer.to, curOffer.fromNftIds[i]);
            IERC721(viridianNFT).safeTransferFrom(_curOffer.from, _curOffer.to, _curOffer.toNftIds[i]);
        }

        // Loop through all of the from items in the offer.
        for (uint i = 0; i < _curOffer.fromNftIds.length; i++) {
            // IERC721(viridianNFT).approve(curOffer.to, curOffer.fromNftIds[i]);
            IERC721(viridianNFT).safeTransferFrom(_curOffer.to, _curOffer.from, _curOffer.fromNftIds[i]);
        }
    }

    /**
     * @dev Gets the current offer from the users current offers.
     */
    function getCurOffer(Offer storage curOffer, Offer[] storage curUserOffers) private view returns (Offer storage) {
        for (uint i = 0; i < curUserOffers.length; i++) {
            Offer memory offer = curUserOffers[i];
            if (offer.offerId == curOffer.offerId) {
                return curUserOffers[i]; //.pending = false;
            }
        }

        return curUserOffers[0];
    }
    
    /**
     * @dev Accepts the offer and moves all respecting ERC20 and ERC721 contents to the destinations laid out in the offer.
     */
    function acceptOfferWithERC20(uint256 _offerId) public {
        Offer storage curOffer = offers[_offerId];

        require(curOffer.to == msg.sender, "Only offered account can accept offer");
        require(!hasOfferExpired(_offerId), "Offer has expired");

        Offer[] storage curUserOffers = userOffers[curOffer.to];
        Offer[] storage otherUserOffers = userOffers[curOffer.from];

        Offer storage setOffer = getCurOffer(curOffer, curUserOffers);
        Offer storage setOfferOther = getCurOffer(curOffer, otherUserOffers);

        doOfferingPartiesOwnContents(curOffer);

        // Transfer all ERC20 tokens to correct respective parties.
        IERC20(curOffer.erc20Address).transferFrom(curOffer.from, treasuryAddress, (curOffer.toAmt / 100) * baseRoyalty);
        IERC20(curOffer.erc20Address).transferFrom(curOffer.from, curOffer.to, curOffer.toAmt - ((curOffer.toAmt / 100) * baseRoyalty));

        IERC20(curOffer.erc20Address).transferFrom(curOffer.to, treasuryAddress, (curOffer.fromAmt / 100) * baseRoyalty);
        IERC20(curOffer.erc20Address).transferFrom(curOffer.to, curOffer.from, curOffer.fromAmt - ((curOffer.fromAmt / 100) * baseRoyalty));

        // Transfer all ERC721 tokens to correct respective parties.
        transferAllOfferContents(curOffer);

        // Disable all offers and set them as no longer pending
        curOffer.pending = false;
        setOffer.pending = false;
        setOfferOther.pending = false;

        emit AcceptedOffer(_offerId, msg.sender, true);
    }
}