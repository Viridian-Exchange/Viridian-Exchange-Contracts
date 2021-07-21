pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ViridianNFT.sol";

contract ViridianExchange is Ownable {

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
        bool sold;
    }

    struct Collection {
        string description;
        uint256[] collectionNFTs;
    }

    //string[] public nftIds;
    mapping (address => Collection) displayCases;
    mapping (address => Listing[]) userListings;
    mapping (uint256 => Listing) listings;
    uint256[] private listingIds;
    User[] public users;

    address public viridianNFT;
    address public ETH;
    address public viridianToken;

    constructor( address _viridianToken, address _viridianNFT) {
        require(address(_viridianToken) != address(0)); 
        //require(address(_ETH) != address(0));
        require(address(_viridianNFT) != address(0));

        viridianToken = _viridianToken;
        //address _ETH, ETH = _ETH;
        viridianNFT = _viridianNFT;
    }

    function getListings() public view returns (uint256[] memory) {
        return listingIds;
    }

    function getListingFromId(uint256 _listingId) public view returns (Listing memory) {
        return listings[_listingId];
    }

    function getNftOwner(uint256 _nftId) public view returns (address) {
        return IERC721(viridianNFT).ownerOf(_nftId);
    }

    function sendEther(address payable _to, uint256 _amount) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function buyNFTWithETH(uint256 _listingId) public payable {
        Listing memory curListing = listings[_listingId];

        require(msg.sender.balance >= curListing.price, 'ViridianExchange: User does not have enough balance');
        address payable ownerWallet = payable(curListing.owner);
        sendEther(ownerWallet, curListing.price);
        
        IERC721(viridianNFT).safeTransferFrom(curListing.owner, msg.sender, curListing.tokenId);
    }

    function buyNFTWithVEXT(uint256 _listingId) public payable {
        Listing memory curListing = listings[_listingId];

        require(IERC20(viridianToken).balanceOf(msg.sender) >= curListing.price, 'ViridianExchange: User does not have enough balance');
        
        IERC20(viridianToken).transferFrom(curListing.owner, msg.sender, curListing.price);
        IERC721(viridianNFT).safeTransferFrom(curListing.owner, msg.sender, curListing.tokenId);
    }

    function acceptOffer() public {
        
    }

    function bidOnAuction() public {

    }

    function putUpForSale(uint256 _nftId, uint256 _price, uint256 _royalty, bool _isAuction, uint256 _endTime) public payable {
        require(getNftOwner(_nftId) == msg.sender);

        _listingIds.increment();
        uint256 _listingId = _listingIds.current();
        Listing memory saleListing = Listing(_listingId, _nftId, msg.sender, _price, false, _royalty, _isAuction, _endTime, false);
        userListings[msg.sender].push(saleListing);
        listings[_listingId] = saleListing;
        listingIds.push(saleListing.listingId);
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