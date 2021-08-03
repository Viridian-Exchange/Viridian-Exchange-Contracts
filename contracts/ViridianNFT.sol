pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ViridianNFT is ERC721, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(string => uint8) hashes;
    
    constructor() ERC721("Viridian NFT", "VNFT") {}

    using Strings for uint256;


    //TODO: Maybe add restrictions to NFT usage when it is listed on the exchange, do not allow ownership transfer 
    // while it is listed for sale or offer to avoid issues with invalid purchasing, or just protect from transactions going through
    // on exchange, ask someone about this scenario.
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

    // function setExchangeAddress(address ea) public onlyOwner() {
    //     viridianExchangeAddress = ea;
    // }
    
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

    function mint(
        address _to,
        string memory tokenURI_
    ) external onlyOwner() {
        _tokenIds.increment();
        uint256 _tokenId = _tokenIds.current();

        _mint(_to, _tokenId);
        _ownedNFTs[_to].push(_tokenId);
        _tokensListed[_tokenId] = false;
        _setTokenURI(_tokenId, tokenURI_);
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