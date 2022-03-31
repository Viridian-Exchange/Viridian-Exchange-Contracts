// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

import "./ViridianNFT.sol";

contract ViridianGenesisPack is ERC721, Ownable, BaseRelayRecipient {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _unmintedTokenIds;
    mapping(string => uint8) hashes;
    mapping(uint256 => string) private _mintURIs;
    string public packURI;
    string private mintURIPrefix;
    uint private mintURIPrefixLen;

    mapping(address => bool) admins;

    address public viridianNFTAddr;

    ViridianNFT vNFT;

    using Strings for uint256;

    constructor(address _viridianNFT, address _forwarder, string memory _packURI) ERC721("Viridian Genesis Pack", "VGP") {

        require(address(_viridianNFT) != address(0));

        viridianNFTAddr = _viridianNFT;

        _setTrustedForwarder(_forwarder);

        vNFT = ViridianNFT(viridianNFTAddr);

        admins[_msgSender()] = true;

        packURI = _packURI;

        mintURIPrefix = "https://d4xub33rt3s5u.cloudfront.net";
        mintURIPrefixLen = 36;
    }

    string public override versionRecipient = "2.2.0";

    function setTrustedForwarder(address _forwarder) public onlyOwner() {
        _setTrustedForwarder(_forwarder);
    }

    event Open(string newUris);
    event PackResultDecided(uint256 tokenId);
    
    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

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

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
        if (admins[_msgSender()]) {
            return true;
        }

        return super._isApprovedOrOwner(spender, tokenId);
    }

    function addAdmin(address _newAdmin) external onlyOwner() {
        admins[_newAdmin] = true;
    }

    function removeAdmin(address _newAdmin) external onlyOwner() {
        admins[_newAdmin] = false;
    }
    
    function setBaseURI(string memory baseURI_) external onlyAdmin() {
        _baseURIextended = baseURI_;
    }

    function setMintURIPrefix(string memory _newMintURIPrefix) external onlyAdmin() {
        mintURIPrefix = _newMintURIPrefix;
    }

    function setMintURIPrefixLen(uint _newMintURIPrefixLen) external onlyAdmin() {
        mintURIPrefixLen = _newMintURIPrefixLen;
    }
    
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) public virtual onlyAdmin() {
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
            if (_exists(i)) {
                if (ownerOf(i) == _msgSender()) {
                    numOwnedNFTs++;
                }
            }
        }

        return numOwnedNFTs;
    }
 
    function getOwnedNFTs() public view virtual returns (uint256[] memory) {

        uint256[] memory _tokens = new uint256[](getNumOwnedNFTs());

        uint256 curIndex = 0;

        for (uint256 i = 1; i <= _tokenIds.current(); i++) {
            if (_exists(i)) {
                if (ownerOf(i) == _msgSender()) {
                    _tokens[curIndex] = i;
                    curIndex++;
                }
            }
        }
        
        return _tokens;
    }

    function getSlice(uint256 begin, uint256 end, string memory text) public pure returns (string memory) {
        bytes memory a = new bytes(end-begin+1);
        for(uint i=0;i<=end-begin;i++){
            a[i] = bytes(text)[i+begin-1];
        }
        return string(a);    
    }

    function mint(
        uint256 _numMint
    ) public {
        for (uint i; i < _numMint; i++) {
            _tokenIds.increment();
            uint256 _tokenId = _tokenIds.current();

            require(keccak256(abi.encodePacked(getSlice(0, mintURIPrefixLen, _mintURIs[_tokenId]))) == keccak256(abi.encodePacked(mintURIPrefix)), "The prefix of the uri does not match.");
            _safeMint(_msgSender(), _tokenId);
            _setTokenURI(_tokenId, packURI);
            _mintURIs[_tokenId] = _mintURIs[_tokenId];
        }
    }

    function compareStrings(string memory _s, string memory _s1) public pure returns (bool) {
        return (keccak256(abi.encodePacked((_s))) == keccak256(abi.encodePacked((_s1))));
    }

    function openPack(uint256 _tokenId, string memory _newTokenURI) public {

        vNFT.mint(_msgSender(), _newTokenURI);

        _burn(_tokenId);

        emit Open(_newTokenURI);
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId));

        _burn(tokenId);
    }
}