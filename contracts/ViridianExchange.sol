pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ViridianNFT.sol";
import "./ViridianPack.sol";

contract ViridianExchange is Ownable {

    event ItemListed(uint256 listingId, address wallet, bool listed);
    event ItemUnlisted(uint256 listingId, address wallet, bool listed);
    event PurchasedListing(uint256 listingId, address wallet, bool purchased);

    using Counters for Counters.Counter;
    Counters.Counter private _listingIds;

    //address vNFTContract = 

    ViridianNFT vNFT;
    ViridianPack vPack;
    
    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address payable owner;
        uint256 price;
        bool purchased;
        uint256 royalty;
        uint256 endTime;
        bool sold;
        bool isVEXT;
        bool isVNFT;
        uint256 timeListed;
    }

    mapping (address => Listing[]) userListings;
    mapping (uint256 => Listing) listings;
    address[] private userAddresses;
    uint256[] private listingIds;

    address public viridianNFT;
    address public viridianPack;
    address public ETH;
    address public viridianToken;

    constructor(address _viridianToken, address _viridianNFT, address _viridianPack) {
        require(address(_viridianToken) != address(0), "Token address must not be the 0 address");
        //require(address(_ETH) != address(0));
        require(address(_viridianNFT) != address(0), "Token address must not be the 0 address");
        require(address(_viridianPack) != address(0), "Token address must not be the 0 address");

        viridianToken = _viridianToken;
        //address _ETH, ETH = _ETH;
        viridianNFT = _viridianNFT;
        viridianPack = _viridianPack;

        vNFT = ViridianNFT(_viridianNFT);
        vPack = ViridianPack(_viridianPack);
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

    function sendEther(address payable _to) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    function putUpForSale(uint256 _nftId, uint256 _price, uint256 _royalty, uint256 _endTime, bool _isVEXT, bool _isVNFT) public {
        if (_isVNFT) {
            require(getNftOwner(_nftId) == msg.sender, 'Must be owner to list vnft');
            require(!vNFT.isListed(_nftId), "Cannot create multiple listings for one nft");
        }
        else {
            require(getPackOwner(_nftId) == msg.sender, 'Must be owner to list pack');
            require(!vPack.isListed(_nftId), "Cannot create multiple listings for one pack");
        }
        
        

        //TODO: Maybe put this back
        // if(!IERC721(viridianNFT).isApprovedForAll(msg.sender, address(this))) {
        //     IERC721(viridianNFT).setApprovalForAll(address(this), true);
        // }

        // if(!IERC721(viridianPack).isApprovedForAll(msg.sender, address(this))) {
        //     IERC721(viridianPack).setApprovalForAll(address(this), true);
        // }

        _listingIds.increment();
        uint256 _listingId = _listingIds.current();
        Listing memory saleListing;
        saleListing.listingId = _listingId;
        saleListing.tokenId = _nftId;
        saleListing.owner = payable(msg.sender);
        saleListing.price = _price;
        saleListing.purchased = false;
        saleListing.royalty = _royalty;
        saleListing.endTime = _endTime;
        saleListing.sold = false;
        saleListing.isVEXT = _isVEXT;
        saleListing.isVNFT = _isVNFT;
        saleListing.timeListed = block.timestamp;

        //_listingId, _nftId, msg.sender, _price, false, 
        //                                    _royalty, _isAuction, _endTime, Bid(msg.sender, 0, _isVEXT), new Bid[](0), false, _isVEXT);
        userListings[msg.sender].push(saleListing);
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
        //IERC721(viridianNFT).safeTransferFrom(msg.sender, address(this), _nftId);

        emit ItemListed(_listingId, saleListing.owner, true);
    }

    function changeSalePrice(uint256 _listingId, uint256 _newPrice) public {
        listings[_listingId].price = _newPrice;
    }
    
    function pullFromSale(uint256 _listingId) public {
        Listing memory curListing = listings[_listingId];
        require(curListing.owner == msg.sender, "Must be the owner to pull from sale");
        //IERC721(viridianNFT).safeTransferFrom(address(this), msg.sender, curListing.tokenId);
        if(curListing.isVNFT) {
            vNFT.unlistToken(curListing.tokenId);
        }
        else {
            vPack.unlistToken(curListing.tokenId);
        }

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

        emit ItemUnlisted(_listingId, msg.sender, false);
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

    function buyNFTWithVEXT(uint256 _listingId) public {
        Listing memory curListing = listings[_listingId];
        require(curListing.isVEXT, "Cannot purchase an ETH listing with USDT");

        if(curListing.isVNFT) {
            vNFT.unlistToken(curListing.tokenId);

            IERC20(viridianToken).transferFrom(msg.sender, curListing.owner, curListing.price);

            IERC721(viridianNFT).approve(msg.sender, curListing.tokenId);
            IERC721(viridianNFT).safeTransferFrom(curListing.owner, msg.sender, curListing.tokenId);
            pullFromSaleOnBuy(_listingId);
        }
        else {
            vPack.unlistToken(curListing.tokenId);

            IERC20(viridianToken).transferFrom(msg.sender, curListing.owner, curListing.price);

            IERC721(viridianPack).approve(msg.sender, curListing.tokenId);
            IERC721(viridianPack).safeTransferFrom(curListing.owner, msg.sender, curListing.tokenId);
            pullFromSaleOnBuy(_listingId);
        }
        emit PurchasedListing(_listingId, msg.sender, true);
    }

    function buyNFTWithETH(uint256 _listingId) public payable {
        Listing memory curListing = listings[_listingId];
        require(!curListing.isVEXT, "Cannot purchase a USDT listing with ETH");

        if(curListing.isVNFT) {
            vNFT.unlistToken(curListing.tokenId);

            //Replace this with ETH implementation
            //IERC20(viridianToken).transferFrom(msg.sender, curListing.owner, curListing.price);
            require(curListing.price == msg.value, "Must send correct amount of ETH to owner of listing");
            curListing.owner.transfer(msg.value);

            //IERC721(viridianNFT).approve(msg.sender, curListing.tokenId);
            IERC721(viridianNFT).safeTransferFrom(curListing.owner, msg.sender, curListing.tokenId);
            pullFromSaleOnBuy(_listingId);
        }
        else {
            vPack.unlistToken(curListing.tokenId);

            //Replace this with ETH implementation
            //IERC20(viridianToken).transferFrom(msg.sender, curListing.owner, curListing.price);
            require(curListing.price == msg.value, "Must send correct amount of ETH to owner of listing");
            curListing.owner.transfer(msg.value);

            //IERC721(viridianPack).approve(msg.sender, curListing.tokenId);
            IERC721(viridianPack).safeTransferFrom(curListing.owner, msg.sender, curListing.tokenId);
            pullFromSaleOnBuy(_listingId);
        }
        emit PurchasedListing(_listingId, msg.sender, true);
    }

    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}