pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ViridianNFT.sol";

contract ViridianExchange {

    struct Trade {
        uint[] nftIds;
        uint vextAmt;
        address _to;
        address _from;
        bool pending;
    }

    struct Listing {
        uint256 tokenId;
        address tokenAddress;
        address owner;
        uint256 price;
        bool purchased;
        bool royalty;
        bool auction;
        uint256 endTime;
    }

    ViridianNFT[] public nfts;
    ViridianNFT[] public displayCase;

    function putUpForSale() public {

    }

    function pullFromSale() public {

    }
}