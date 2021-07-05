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

    struct Listing {
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
        ViridianNFT[] collectionNFTs;
    }

    string[] public nftIds;
    mapping (address => Collection) displayCases;
    mapping (address => Listing[]) userListings;
    User[] public users;

    function putUpForSale(uint256 _nftId, uint256 _price, uint256 _royalty, bool _isAuction, uint256 _endTime) public {
        Listing memory saleListing = Listing(_nftId, msg.sender, _price, false, _royalty, _isAuction, _endTime);
        userListings[msg.sender].push(saleListing);
    }

    function pullFromSale() public {

    }
}