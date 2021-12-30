pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

contract ViridianNFT is ERC721, Ownable, BaseRelayRecipient {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(string => uint8) hashes;
    
    mapping(address => bool) admins;
    
    // constructor(address _imx) ERC721("Viridian NFT", "VNFT") Mintable(_msgSender(), _imx) {
    //     admins[_msgSender()] = true;
    // }

    constructor(/*address _forwarder*/) ERC721("Viridian NFT", "VNFT") {
        //_setTrustedForwarder(_forwarder);
        
        admins[_msgSender()] = true;
    }

    string public override versionRecipient = "2.2.0";

    function setTrustedForwarder(address _forwarder) public onlyOwner() {
        _setTrustedForwarder(_forwarder);
    }

    using Strings for uint256;

    //TODO: Maybe add restrictions to NFT usage when it is listed on the exchange, do not allow ownership transfer 
    // while it is listed for sale or offer to avoid issues with invalid purchasing, or just protect from transactions going through
    // on exchange, ask someone about this scenario.


    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    //mapping(uint256 => bytes) public blueprints;

    mapping (uint256 => bool) private _tokensListed;

    //address private viridianExchangeAddress;

    // Base URI
    string private _baseURIextended;

    modifier onlyAdmin() {
        require(admins[_msgSender()] == true);
            _;
    }

    function _msgSender() internal view override(Context, BaseRelayRecipient) returns (address sender) {
        sender = BaseRelayRecipient._msgSender();
    }

    function _msgData() internal view override(Context, BaseRelayRecipient) returns (bytes memory) {
        return BaseRelayRecipient._msgData();
    }

    function addAdmin(address _newAdmin) external onlyOwner() {
        admins[_newAdmin] = true;
    }

    function removeAdmin(address _newAdmin) external onlyOwner() {
        admins[_newAdmin] = false;
    }

    // function setExchangeAddress(address ea) public onlyOwner() {
    //     viridianExchangeAddress = ea;
    // }
    
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }
    
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) public virtual onlyOwner() {
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

    function getNumNFTs() public view returns (uint256 n) {
        return _tokenIds.current();
    }

    function getNumOwnedNFTs() public view virtual returns (uint256) {
        uint256 numOwnedNFTs = 0;

        for (uint256 i = 1; i <= _tokenIds.current(); i++) {
            if (ownerOf(i) == _msgSender()) {
                numOwnedNFTs++;
            }
        }

        return numOwnedNFTs;
    }
 
    function getOwnedNFTs() public view virtual returns (uint256[] memory) {

        uint256[] memory _tokens = new uint256[](getNumOwnedNFTs());

        uint256 curIndex = 0;

        for (uint256 i = 1; i <= _tokenIds.current(); i++) {
            if (ownerOf(i) == _msgSender()) {
                _tokens[curIndex] = i;
                curIndex++;
            }
        }
        
        return _tokens;
    }

    function mint(
        address _to,
        string memory tokenURI_
    ) external onlyAdmin() {
        _tokenIds.increment();
        uint256 _tokenId = _tokenIds.current();

        _safeMint(_to, _tokenId);
        _tokensListed[_tokenId] = false;
        _setTokenURI(_tokenId, tokenURI_);
    }

    function isListed(uint256 tokenId) public view returns (bool) {
        return _tokensListed[tokenId];
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId));

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
        require(!_tokensListed[tokenId], "Viridian NFT: Cannot transfer while listed on Viridian Exchange");

        super.safeTransferFrom(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(!_tokensListed[tokenId], "Viridian NFT: Cannot transfer while listed on Viridian Exchange");

        super.transferFrom(from, to, tokenId);
    }

    function listToken(uint256 _tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), _tokenId));
        _tokensListed[_tokenId] = true;
    }

    function unlistToken(uint256 _tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), _tokenId));
        _tokensListed[_tokenId] = false;
    }
}