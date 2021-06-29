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
    }

    ViridianNFT[] public nfts;

    function putUpForSale() public {

    }

    function pullFromSale() public {

    }
}