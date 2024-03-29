pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@imtbl/imx-contracts/contracts/Mintable.sol";

contract ViridianNFT is ERC721, Ownable, Mintable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(string => uint8) hashes;
    
    mapping(address => bool) admins;
    
    // constructor(address _imx) ERC721("Viridian NFT", "VNFT") Mintable(msg.sender, _imx) {
    //     admins[msg.sender] = true;
    // }

    constructor() ERC721("Viridian NFT", "VNFT") Mintable() {
        addAdmin(msg.sender);
        //IMX testnet address
        addAdmin(0x4527be8f31e2ebfbef4fcaddb5a17447b27d2aef);
    }

    using Strings for uint256;

    //TODO: Maybe add restrictions to NFT usage when it is listed on the exchange, do not allow ownership transfer 
    // while it is listed for sale or offer to avoid issues with invalid purchasing, or just protect from transactions going through
    // on exchange, ask someone about this scenario.


    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    mapping(uint256 => bytes) public blueprints;

    mapping (uint256 => bool) private _tokensListed;

    //address private viridianExchangeAddress;

    // Base URI
    string private _baseURIextended;

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

    function getOwnedNFTs() public view virtual returns (uint256[] memory) {
        uint256[] memory _tokens = [];

        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            if (ownerOf(tokenId) == msg.sender) {
                _tokens.push(tokenId);
            }
        }
        
        return _tokens;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] == true);
            _;
    }

    function addAdmin(address _newAdmin) external onlyOwner() {
        admins[_newAdmin] = true;
    }

    function removeAdmin(address _newAdmin) external onlyOwner() {
        admins[_newAdmin] = false;
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

    function mintFor(
        address user,
        uint256 quantity,
        bytes calldata mintingBlob
    ) external override onlyAdmin() {
        require(quantity == 1, "Mintable: invalid quantity");
        (uint256 id, bytes memory blueprint) = Minting.split(mintingBlob);
        _mintFor(user, id, blueprint);
        super.blueprints[id] = blueprint;
        emit super.AssetMinted(user, id, blueprint);
    }

    function isListed(uint256 tokenId) public view returns (bool) {
        return _tokensListed[tokenId];
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));

        address owner = ownerOf(tokenId);

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
        _tokensListed[_tokenId] = true;
    }

    function unlistToken(uint256 _tokenId) public {
        _tokensListed[_tokenId] = false;
    }
}