// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "erc721a/contracts/IERC721A.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

import "./ViridianGenesisNFT.sol";

/**
 * Exchange contract that helps facilitate the buying and selling on Viridian NFTs.
 * Will support cross-chain purcahsing whether the NFT or listing is on that chain or not.
 */
contract ViridianExchange is BaseRelayRecipient, Ownable {

    // Events to assist listing, purchasing, and unlisting visuals on front-end.
    event ItemListed(uint256 tokenId, string uri, address wallet, bool listed);
    event ItemUnlisted(uint256 tokenId, string uri, address wallet, bool listed);
    event PurchasedListing(uint256 tokenId, uint256 price, string uri, address wallet, bool purchased);

    // Incrementing counter for listing Ids
    using Counters for Counters.Counter;
    Counters.Counter private _listingIds;

    // Viridian Genesis NFT instance
    ViridianGenesisNFT vNFT;
    
    // Struct with all information for a listing
    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        uint256 chainId;
        address owner;
        uint256 price;
        bool purchased;
        uint256 baseRoyalty;
        uint256 endTime;
        bool sold;
        address erc20Address;
        uint256 timeListed;
    }

    // All listings that an individual user has made (Maybe remove for gas optimization on Ethereum)
    mapping (address => Listing[]) userListings;

    // All listings on the exchange
    mapping (uint256 => Listing) listings;
    // All listing sales that have been completed on the platform
    mapping (uint256 => Listing) soldListings;
    // All tokens that are not allowed to be listed on the platform
    mapping (uint256 => bool) tokenIdBlacklist;

    // All listing ids on the site (Maybe remove for gas optimization)
    uint256[] private listingIds;

    // All listing ids of sales that have been completed on the platform
    uint256[] private soldListingIds;

    // Base royalty amount for site transactions
    uint256 private baseRoyalty;
    // Royalty for users who are recieving promotional rates
    uint256 private whitelistRoyalty;
    // Treasury address where royalty payments are sent to
    address private treasuryAddress;

    // The current address for the Viridian NFT Contract
    address public viridianNFT;

    // All approved ERC20 tokens that can be used on the site.
    mapping (address => bool) public approvedTokens;

    /**
     * @dev Set the default ERC20Token address, Viridian NFT address, forwarder for gasless, and treasury for royalty payments.
     */
    constructor(address _erc20Token, address _viridianNFT, address _forwarder, address _treasury) {
        require(address(_erc20Token) != address(0), "Token address must not be the 0 address");
        require(address(_viridianNFT) != address(0), "Token address must not be the 0 address");

        treasuryAddress = _treasury;
        baseRoyalty = 5;
        whitelistRoyalty = 0;

        setTrustedForwarder(_forwarder);

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
     * @dev Returns whether the ERC20 token is supported on the exchange.
     */
    function isTokenApproved(address _erc20Address) public view returns (bool) {
        return approvedTokens[_erc20Address];
    }

    /**
     * @dev Gets the balance of the exchange contract.
     */
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    /**
     * @dev Gets all listing ids that are currently on the exchange.
     */
    function getListings() public view returns (uint256[] memory) {
        return listingIds;
    }

    /**
     * @dev Gets the listing struct from a listing Id.
     */
    function getListingFromId(uint256 _listingId) public view returns (Listing memory) {
        return listings[_listingId];
    }

    /**
     * @dev Gets all listings a user has on the exchange.
     */
    function getListingsFromUser(address _userAddr) public view returns (Listing[] memory) {
        return userListings[_userAddr];
    }

    /**
     * @dev Gets the owner of an NFT on the exchange.
     */
    function getNftOwner(uint256 _nftId) public view returns (address) {
        return IERC721(viridianNFT).ownerOf(_nftId);
    }

    /**
     * @dev User can put one of their NFTs up for sale.
     */
    function putUpForSale(uint256 _nftId, uint256 _price, uint256 _royalty, uint256 _endTime, address _erc20Address) public {
        // All listing restrictions must be enforced
        require(approvedTokens[_erc20Address], "Must be listed price in approved token");
        require(tokenIdBlacklist[_nftId], "Cannot make a listing for a blacklisted vNFT");
        require(getNftOwner(_nftId) == _msgSender(), "Must be owner to list vNFT");

        // Set all data on the listing struct
        _listingIds.increment();
        uint256 _listingId = _listingIds.current();
        Listing memory saleListing;
        saleListing.listingId = _listingId;
        saleListing.tokenId = _nftId;
        saleListing.owner = _msgSender();
        saleListing.price = _price;
        saleListing.purchased = false;
        saleListing.baseRoyalty = _royalty;
        saleListing.endTime = _endTime;
        saleListing.sold = false;
        saleListing.erc20Address = _erc20Address;
        saleListing.timeListed = block.timestamp;

        // Push the listing to the current senders listings and the array of exchange listings.
        userListings[_msgSender()].push(saleListing);
        listings[_listingId] = saleListing;
        listingIds.push(saleListing.listingId);

        emit ItemListed(_nftId, vNFT.tokenURI(_nftId), saleListing.owner, true);
    }

    /**
     * @dev User can put one of their NFTs up for sale.
     */
    function changeSalePrice(uint256 _listingId, uint256 _newPrice) public {
        require(listings[_listingId].owner == _msgSender(), "Must be owner to change listing price");
        listings[_listingId].price = _newPrice;
    }
    
    /**
     * @dev User can remove one of their listings from the exchange.
     */
    function pullFromSale(uint256 _listingId) public {
        Listing memory curListing = listings[_listingId];
        require(curListing.owner == _msgSender(), "Must be the owner to pull from sale");

        Listing[] storage curUserListings = userListings[_msgSender()];
        for (uint i = 0; i < curUserListings.length; i++) {
            Listing memory listing = curUserListings[i];
            if (listing.listingId == curListing.listingId) {
                curUserListings[i] = curUserListings[curUserListings.length - 1];
                userListings[_msgSender()] = curUserListings;
                userListings[_msgSender()].pop();
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

        emit ItemUnlisted(curListing.tokenId, vNFT.tokenURI(curListing.tokenId), _msgSender(), false);
    }

    /**
     * @dev When a listing is purchased remove listing and add it to sold listings.
     */
    function pullFromSaleOnListingPurchase(uint256 _listingId) private {
        Listing memory curListing = listings[_listingId];
        //IERC721(viridianNFT).safeTransferFrom(address(this), _msgSender(), curListing.tokenId);
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

        //TODO: Make sure this is correct
        soldListings[_listingId] = curListing;
        soldListingIds.push(_listingId);

        delete listings[_listingId];
    }

    /**
     * @dev Purchase listing for an NFT with an ERC20 token payment.
     */
    function purchaseListing(uint256 _listingId) public {
        Listing memory curListing = listings[_listingId];

        require(curListing.owner == IERC721(viridianNFT).ownerOf(curListing.tokenId), "Listing inactive: listing creator not longer owns the token.");

        IERC20(curListing.erc20Address).transferFrom(_msgSender(), treasuryAddress, (curListing.price / 100) * baseRoyalty);
        IERC20(curListing.erc20Address).transferFrom(_msgSender(), curListing.owner, curListing.price - ((curListing.price / 100) * baseRoyalty));

        IERC721(viridianNFT).approve(_msgSender(), curListing.tokenId);
        IERC721(viridianNFT).safeTransferFrom(curListing.owner, _msgSender(), curListing.tokenId);
        pullFromSaleOnListingPurchase(_listingId);

        emit PurchasedListing(curListing.tokenId, curListing.price, vNFT.tokenURI(curListing.tokenId), _msgSender(), true);
    }

    /**
     * @dev Purchase listing for an NFT on a different chain with an ERC20 token payment using stargate.
     */
    function purchaseListingOmniChain(uint256 _listingId) public {
        Listing memory curListing = listings[_listingId];

        require(curListing.owner == IERC721(viridianNFT).ownerOf(curListing.tokenId), "Listing inactive: listing creator not longer owns the token.");
        
        
        IERC20(curListing.erc20Address).transferFrom(_msgSender(), treasuryAddress, (curListing.price / 100) * baseRoyalty);
        // TODO: Transfer payment money with stargate
        IERC20(curListing.erc20Address).transferFrom(_msgSender(), curListing.owner, curListing.price - ((curListing.price / 100) * baseRoyalty));

        IERC721(viridianNFT).approve(_msgSender(), curListing.tokenId);
        IERC721(viridianNFT).safeTransferFrom(curListing.owner, _msgSender(), curListing.tokenId);
        pullFromSaleOnListingPurchase(_listingId);
        
        emit PurchasedListing(curListing.tokenId, curListing.price, vNFT.tokenURI(curListing.tokenId), _msgSender(), true);
    }

    /**
     * @dev Reimburse every address that purcahsed a listing involving the tokenId.
     */
    function rollbackSales(uint256 _tokenId) external onlyOwner() {
        // Loop through all previous sales that contain the _tokenId
        // Put then in order in a list
        // Loop through in-order, reimburse the current holder the full amount they paid, and reimburse the
        // initial purchase price - final sale price if the final sale is lower than the purchase/
    }
}