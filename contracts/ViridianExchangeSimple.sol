pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

import "./ViridianNFT.sol";

abstract contract ViridianExchangeSimple is Ownable, BaseRelayRecipient {

    event ItemListed(uint256 listingId, address wallet, bool listed);
    event ItemUnlisted(uint256 listingId, address wallet, bool listed);
    event PurchasedListing(uint256 listingId, address wallet, bool purchased);

    using Counters for Counters.Counter;
    Counters.Counter private _listingIds;

    ViridianNFT vNFT;
    
    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address owner;
        uint256 price;
        uint256 royalty;
        bool purchased;
        bool sold;
        address erc20Address;
        uint256 timeListed;
    }

    mapping (address => Listing[]) userListings;
    mapping (uint256 => Listing) listings;
    address[] private userAddresses;
    uint256[] private listingIds;

    address public viridianNFT;
    mapping (address => bool) public approvedTokens;

    constructor(address _erc20Token, address _viridianNFT) {
        require(address(_erc20Token) != address(0), "Token address must not be the 0 address");
        require(address(_viridianNFT) != address(0), "Token address must not be the 0 address");

        approvedTokens[_erc20Token] = true;
        viridianNFT = _viridianNFT;

        vNFT = ViridianNFT(_viridianNFT);
    }

    function _msgSender() internal view override(Context, BaseRelayRecipient) returns (address) {
        return BaseRelayRecipient._msgSender();
    }

    function _msgData() internal view override(Context, BaseRelayRecipient) returns (bytes memory) {
        return BaseRelayRecipient._msgData();
    } 

    function addERC20Token(address _erc20Address) public onlyOwner() {
        approvedTokens[_erc20Address] = true;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getListings() public view returns (uint256[] memory) {
        return listingIds;
    }

    function getListingFromId(uint256 _listingId) public view returns (Listing memory) {
        return listings[_listingId];
    }

    function getListingsFromUser(address _userAddr) public view returns (Listing[] memory) {
        return userListings[_userAddr];
    }

    function getNftOwner(uint256 _nftId) public view returns (address) {
        return IERC721(viridianNFT).ownerOf(_nftId);
    }

    function mintAndList(string memory newURI, uint256 _price, address _erc20Address) public onlyOwner() {
        vNFT.mint(msg.sender, newURI);

        putUpForSale(vNFT.getNumNFTs(), _price, 0, _erc20Address);
    }

    function putUpForSale(uint256 _nftId, uint256 _price, uint256 _royalty, address _erc20Address) private {
        require(approvedTokens[_erc20Address], "Must be listed price in approved token");

        require(getNftOwner(_nftId) == _msgSender(), "Must be owner to list vnft");
        require(!vNFT.isListed(_nftId), "Cannot create multiple listings for one nft");

        _listingIds.increment();
        uint256 _listingId = _listingIds.current();
        Listing memory saleListing;
        saleListing.listingId = _listingId;
        saleListing.tokenId = _nftId;
        saleListing.owner = _msgSender();
        saleListing.price = _price;
        saleListing.purchased = false;
        saleListing.royalty = _royalty;
        saleListing.sold = false;
        saleListing.erc20Address = _erc20Address;
        saleListing.timeListed = block.timestamp;


        userListings[_msgSender()].push(saleListing);
        listings[_listingId] = saleListing;
        listingIds.push(saleListing.listingId);

        vNFT.listToken(_nftId);

        //ERC20(viridianToken).approve(address(this), _price);

        //IERC721(viridianNFT).approve(address(this), _nftId);
        //IERC721(viridianNFT).safeTransferFrom(_msgSender(), address(this), _nftId);

        emit ItemListed(_listingId, saleListing.owner, true);
    }

    function changeSalePrice(uint256 _listingId, uint256 _newPrice) public {
        listings[_listingId].price = _newPrice;
    }
    
    function pullFromSale(uint256 _listingId) public {
        Listing memory curListing = listings[_listingId];
        require(curListing.owner == _msgSender(), "Must be the owner to pull from sale");
        //IERC721(viridianNFT).safeTransferFrom(address(this), _msgSender(), curListing.tokenId);
        vNFT.unlistToken(curListing.tokenId);

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

        emit ItemUnlisted(_listingId, _msgSender(), false);
    }

    function pullFromSaleOnBuy(uint256 _listingId) private {
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

        delete listings[_listingId];
    }

    function buyNFTWithERC20(uint256 _listingId) public {
        Listing memory curListing = listings[_listingId];

        vNFT.unlistToken(curListing.tokenId);

        IERC20(curListing.erc20Address).transferFrom(_msgSender(), curListing.owner, curListing.price);

        IERC721(viridianNFT).approve(_msgSender(), curListing.tokenId);
        IERC721(viridianNFT).safeTransferFrom(curListing.owner, _msgSender(), curListing.tokenId);
        pullFromSaleOnBuy(_listingId);

        emit PurchasedListing(_listingId, _msgSender(), true);
    }
}