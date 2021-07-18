pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ViridianNFT.sol";

contract ViridianExchange {

    struct User {
        address wallet;
        string displayName;
        string coverPhotoURL;
        string profilePhotoURL;
        string bio;
        User[] following;
        User[] followers;
        uint256[] likes;
    }

    struct Trade {
        uint256[] nftIds;
        uint vextAmt;
        address _to;
        address _from;
        bool pending;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _listingIds;

    //address vNFTContract = 
    
    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address owner;
        uint256 price;
        bool purchased;
        uint256 royalty;
        bool isAuction;
        uint256 endTime;
    }

    struct Collection {
        string description;
        uint256[] collectionNFTs;
    }

    //string[] public nftIds;
    mapping (address => Collection) displayCases;
    mapping (address => Listing[]) userListings;
    Listing[] private listings;
    User[] public users;

    function getListings() public view returns (Listing[] memory) {
        return listings;
    }

    // function getNftOwner(address vnftAddr, uint256 _nftId) public payable returns (bytes memory) {
    //     (bool success, bytes memory data) = vnftAddr.call{value: msg.value, gas: 100000}(
    //             abi.encodeWithSignature("ownerOf(uint256)", _nftId));
        
    //     return data;
    // }

    function putUpForSale(uint256 _nftId, uint256 _price, uint256 _royalty, bool _isAuction, uint256 _endTime, address vnftAddr) public payable {
        //require(nftOwner == msg.sender);
        // Figure out a way to get this require to work
        _listingIds.increment();
        uint256 _listingId = _listingIds.current();
        Listing memory saleListing = Listing(_listingId, _nftId, msg.sender, _price, false, _royalty, _isAuction, _endTime);
        userListings[msg.sender].push(saleListing);
        listings.push(saleListing);
    }

    function pullFromSale(Listing memory _listing) public {
        require(_listing.owner == msg.sender);
        Listing[] storage curUserListings = userListings[msg.sender];
        for (uint i = 0; i < curUserListings.length; i++) {
            Listing memory listing = curUserListings[i];
            if (listing.listingId == _listing.listingId) {
                curUserListings[i] = curUserListings[curUserListings.length - 1];
                userListings[msg.sender] = curUserListings;
                userListings[msg.sender].pop();
                break;
            }
        }
    }

    function withdrawNFT() public {
        //Burn NFT
        //Send message to prompt front-end email sending
    }
}