pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./RandomNumber.sol";
import "./ViridianNFT.sol";

contract ViridianPack is ERC721, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _unmintedTokenIds;
    mapping(string => uint8) hashes;
    mapping(uint256 => mapping(uint256 => uint256)) private rarityOdds;
    mapping(uint256 => uint256) private numNFTs;
    //mapping(uint256 => string) private unmintedURIs;
    mapping(uint256 => uint256) tokenRarity;
    mapping(uint256 => string[]) private uriRarityPools;
    int private maxRarityIndex;

    address public viridianNFTAddr;

    ViridianNFT vNFT;

    using Strings for uint256;

    constructor(address _viridianNFT) ERC721("Viridian Pack", "VP") {

        require(address(_viridianNFT) != address(0));

        viridianNFTAddr = _viridianNFT;

        vNFT = ViridianNFT(viridianNFTAddr);

        //Set all beginning rarities

        // Legendary rarity and cards in pack
        rarityOdds[0][0] = 25;
        rarityOdds[0][1] = 100;
        rarityOdds[0][2] = 300;
        rarityOdds[0][3] = 1000;
        numNFTs[0] = 3;

        // Mystical rarity and cards in pack
        rarityOdds[1][0] = 1;
        rarityOdds[1][1] = 50;
        rarityOdds[1][2] = 200;
        rarityOdds[1][3] = 1000;
        numNFTs[0] = 3;

        // Rare rarity and cards in pack
        rarityOdds[1][0] = 0;
        rarityOdds[1][1] = 50;
        rarityOdds[1][2] = 100;
        rarityOdds[1][3] = 1000;
        numNFTs[0] = 3;

        // Common rarity and cards in pack
        rarityOdds[2][0] = 0;
        rarityOdds[2][1] = 10;
        rarityOdds[2][2] = 50;
        rarityOdds[2][3] = 1000;
        numNFTs[0] = 3;

        maxRarityIndex = 3;
    }
    
    struct NFT {
        uint256 id;
        string uri;
    }
    
    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    mapping (uint256 => bool) private _tokensListed;

    mapping (address => uint256[]) private _ownedNFTs;

    //address private viridianExchangeAddress;

    // Base URI
    string private _baseURIextended;
    
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }
    
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function getOwnedNFTs() public view virtual returns (uint256[] memory) {
        uint256[] memory _tokens = _ownedNFTs[msg.sender];
        
        return _tokens;
    }

    function setRarityOdds(uint256 _rarity, uint256 _rarityOdd, uint256 _newOdds) external onlyOwner() {
        rarityOdds[_rarity][_rarityOdd] = _newOdds;
    }

    function mint(
        address _to,
        string memory tokenURI_
    ) external onlyOwner() {
        _tokenIds.increment();
        uint256 _tokenId = _tokenIds.current();

        _safeMint(_to, _tokenId);
        _ownedNFTs[_to].push(_tokenId);
        _tokensListed[_tokenId] = false;
        _setTokenURI(_tokenId, tokenURI_);
    }

    //TODO: THIS IS NOT TO BE USED IN FINAL DEPLOYED IMPLEMENTATION, convert to LINK VRF for TESTNET and ESPECIALLY MAINNET!!!
    uint nonce;


    function random(uint range) internal returns (uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % range;
        randomnumber = randomnumber;
        nonce++;

        return randomnumber;
    }

    function calculateWeightedOdds(uint256 randomNum, mapping(uint256 => uint256) storage rarityOdd) private view returns (uint) {
        uint256 n;

        for (n = 0; int(n) < int(maxRarityIndex); n++) {
            if (randomNum <= rarityOdd[n]) {
                return n;
            }
        }

        return n;
    }

    function softMintNFT(string memory uri, uint256 rarity) public onlyOwner() payable {
        uriRarityPools[rarity].push(uri);
    }

    function compareStrings(string memory _s, string memory _s1) public pure returns (bool) {
        return (keccak256(abi.encodePacked((_s))) == keccak256(abi.encodePacked((_s1))));
    }

    function openPack(uint256 _tokenId) public {
        // Randomly 
        require(_isApprovedOrOwner(msg.sender, _tokenId));

        uint256 tr = tokenRarity[_tokenId];

        for (uint8 n = 0; n < numNFTs[tr]; n++) {
            uint256 randIndexWithPercentOdds = calculateWeightedOdds(random(1000), rarityOdds[tr]);
            uint256 randIndexInRarity = random(uriRarityPools[randIndexWithPercentOdds].length - 1);

            string memory newURI = uriRarityPools[randIndexWithPercentOdds][randIndexInRarity];

            vNFT.mint(msg.sender, newURI);

            string[] memory curRarityPool = uriRarityPools[randIndexWithPercentOdds];
            for (uint i = 0; i < uriRarityPools[randIndexWithPercentOdds].length; i++) {
                string memory uri = uriRarityPools[randIndexWithPercentOdds][i];
                if (compareStrings(uri, newURI)) {
                    curRarityPool[i] = curRarityPool[curRarityPool.length - 1];
                    uriRarityPools[randIndexWithPercentOdds] = curRarityPool;
                    uriRarityPools[randIndexWithPercentOdds].pop();
                    break;
                }
            }
        }

        burn(_tokenId);
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        _burn(tokenId);
    }

    function awardItem(address recipient, string memory hash, string memory metadata) public returns (uint256) {
        require(hashes[hash] != 1);
        hashes[hash] = 1;
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, metadata);
        return newItemId;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        require(!_tokensListed[tokenId]);
        for (uint256 i = 0; i < _ownedNFTs[msg.sender].length; i++) {
            uint256 ownedNFT = _ownedNFTs[msg.sender][i];
            if (ownedNFT == tokenId) {
                _ownedNFTs[msg.sender][i] = _ownedNFTs[msg.sender][_ownedNFTs[msg.sender].length - 1];
                _ownedNFTs[msg.sender].pop();
            }
        }
        _ownedNFTs[to].push(tokenId);

        super.safeTransferFrom(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        for (uint256 i = 0; i < _ownedNFTs[msg.sender].length; i++) {
            uint256 ownedNFT = _ownedNFTs[msg.sender][i];
            if (ownedNFT == tokenId) {
                _ownedNFTs[msg.sender][i] = _ownedNFTs[msg.sender][_ownedNFTs[msg.sender].length - 1];
                _ownedNFTs[msg.sender].pop();
            }
        }
        _ownedNFTs[to].push(tokenId);

        super.transferFrom(from, to, tokenId);
    }
}