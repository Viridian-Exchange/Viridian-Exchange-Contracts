pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

import "./ViridianNFT.sol";
import "./ViridianPack.sol";

contract ViridianExchange is BaseRelayRecipient, Ownable {

    event ItemListed(uint256 tokenId, string uri, address wallet, bool listed);
    event ItemUnlisted(uint256 tokenId, string uri, address wallet, bool listed);
    event PurchasedListing(uint256 tokenId, uint256 price, string uri, address wallet, bool purchased);

    using Counters for Counters.Counter;
    Counters.Counter private _listingIds;

    ViridianNFT vNFT;
    ViridianPack vPack;
    
    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address owner;
        uint256 price;
        bool purchased;
        uint256 baseRoyalty;
        uint256 endTime;
        bool sold;
        address erc20Address;
        bool isVNFT;
        uint256 timeListed;
    }

    mapping (address => Listing[]) userListings;
    mapping (uint256 => Listing) listings;
    mapping (uint256 => Listing) soldListings;
    address[] private userAddresses;
    uint256[] private listingIds;
    uint256[] private soldListingIds;

    uint256 private baseRoyalty;
    uint256 private whitelistRoyalty;

    address private treasuryAddress;

    address public viridianNFT;
    address public viridianPack;
    mapping (address => bool) public approvedTokens;

    constructor(address _erc20Token, address _viridianNFT, address _viridianPack, address _forwarder) {
        require(address(_erc20Token) != address(0), "Token address must not be the 0 address");
        require(address(_viridianNFT) != address(0), "Token address must not be the 0 address");
        require(address(_viridianPack) != address(0), "Token address must not be the 0 address");

        treasuryAddress = _msgSender();
        baseRoyalty = 5;
        whitelistRoyalty = 0;

        setTrustedForwarder(_forwarder);

        approvedTokens[_erc20Token] = true;
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

    function setRoyalty(uint256 _newRoyalty) public onlyOwner() {
        baseRoyalty = _newRoyalty;
    }

    function setWhitelistRoyalty(uint256 _newRoyalty) public onlyOwner() {
        baseRoyalty = _newRoyalty;
    }

    function addERC20Token(address _erc20Address) public onlyOwner() {
        approvedTokens[_erc20Address] = true;
    }

    function isTokenApproved(address _erc20Address) public view returns (bool) {
        return approvedTokens[_erc20Address];
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

    function getPackOwner(uint256 _nftId) public view returns (address) {
        return IERC721(viridianPack).ownerOf(_nftId);
    }

    function putUpForSale(uint256 _nftId, uint256 _price, uint256 _royalty, uint256 _endTime, address _erc20Address, bool _isVNFT) public {
        require(approvedTokens[_erc20Address], "Must be listed price in approved token");

        if (_isVNFT) {
            require(getNftOwner(_nftId) == _msgSender(), "Must be owner to list vnft");
            require(!vNFT.isListed(_nftId), "Cannot create multiple listings for one nft");
        }
        else {
            require(getPackOwner(_nftId) == _msgSender(), "Must be owner to list pack");
            require(!vPack.isListed(_nftId), "Cannot create multiple listings for one pack");
        }
        
        //TODO: Maybe put this back
        // if(!IERC721(viridianNFT).isApprovedForAll(_msgSender(), address(this))) {
        //     IERC721(viridianNFT).setApprovalForAll(address(this), true);
        // }

        // if(!IERC721(viridianPack).isApprovedForAll(_msgSender(), address(this))) {
        //     IERC721(viridianPack).setApprovalForAll(address(this), true);
        // }

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
        saleListing.isVNFT = _isVNFT;
        saleListing.timeListed = block.timestamp;


        userListings[_msgSender()].push(saleListing);
        listings[_listingId] = saleListing;
        listingIds.push(saleListing.listingId);

        if (_isVNFT) {
            vNFT.listToken(_nftId);
        }
        else {
            vPack.listToken(_nftId);
        }

        //ERC20(viridianToken).approve(address(this), _price);

        //IERC721(viridianNFT).approve(address(this), _nftId);
        //IERC721(viridianNFT).safeTransferFrom(_msgSender(), address(this), _nftId);

        emit ItemListed(_nftId, vNFT.tokenURI(_nftId), saleListing.owner, true);
    }

    function changeSalePrice(uint256 _listingId, uint256 _newPrice) public {
        listings[_listingId].price = _newPrice;
    }
    
    function pullFromSale(uint256 _listingId) public {
        Listing memory curListing = listings[_listingId];
        require(curListing.owner == _msgSender(), "Must be the owner to pull from sale");
        //IERC721(viridianNFT).safeTransferFrom(address(this), _msgSender(), curListing.tokenId);
        if(curListing.isVNFT) {
            vNFT.unlistToken(curListing.tokenId);
        }
        else {
            vPack.unlistToken(curListing.tokenId);
        }

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

        //TODO: Make sure this is correct
        soldListings[_listingId] = curListing;
        soldListingIds.push(_listingId);

        delete listings[_listingId];
    }

    function buyNFTWithERC20(uint256 _listingId) public {
        Listing memory curListing = listings[_listingId];

        if(curListing.isVNFT) {
            vNFT.unlistToken(curListing.tokenId);

            IERC20(curListing.erc20Address).transferFrom(_msgSender(), curListing.owner, (curListing.price / 100) * baseRoyalty);
            IERC20(curListing.erc20Address).transferFrom(_msgSender(), curListing.owner, curListing.price - ((curListing.price / 100) * baseRoyalty));

            IERC721(viridianNFT).approve(_msgSender(), curListing.tokenId);
            IERC721(viridianNFT).safeTransferFrom(curListing.owner, _msgSender(), curListing.tokenId);
            pullFromSaleOnBuy(_listingId);
        }
        else {
            vPack.unlistToken(curListing.tokenId);

            IERC20(curListing.erc20Address).transferFrom(_msgSender(), curListing.owner, (curListing.price / 100) * baseRoyalty);
            IERC20(curListing.erc20Address).transferFrom(_msgSender(), curListing.owner, curListing.price - ((curListing.price / 100) * baseRoyalty));

            IERC721(viridianPack).approve(_msgSender(), curListing.tokenId);
            IERC721(viridianPack).safeTransferFrom(curListing.owner, _msgSender(), curListing.tokenId);
            pullFromSaleOnBuy(_listingId);
        }
        emit PurchasedListing(curListing.tokenId, curListing.price, vNFT.tokenURI(curListing.tokenId), _msgSender(), true);
    }

    function rollbackSales(uint256 _tokenId) external onlyOwner() {
        // Loop through all previous sales that contain the _tokenId
        // Put then in order in a list
        // Loop through in-order, reimburse the current holder the full amount they paid, and reimburse the
        // initial purchase price - final sale price if the final sale is lower than the purchase/
    }
}