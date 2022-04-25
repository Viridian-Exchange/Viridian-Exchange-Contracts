// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./ViridianNFT.sol";


contract ViridianGenesisPack is ERC721, Ownable, BaseRelayRecipient {

    using Counters for Counters.Counter;
    Counters.Counter private numMinted;
    Counters.Counter private fingerprintIndex;

    string public packURI;

    bool private openingLocked = true;
    bool private allowWhitelistMinting = false;
    bool private allowPublicMinting = false;

    mapping(address => uint8) private _whitelist;

    uint256 public maxMinted = 2000;

    mapping(uint256 => uint256) private hashedTokenIds;

    mapping(address => bool) admins;

    address public viridianNFTAddr;

    ViridianNFT vNFT;

    using Strings for uint256;

    constructor(address _viridianNFT, address _forwarder, string memory _packURI) ERC721("Viridian Genesis Pack", "VGP") {

        require(address(_viridianNFT) != address(0));

        viridianNFTAddr = _viridianNFT;

        _setTrustedForwarder(_forwarder);

        vNFT = ViridianNFT(viridianNFTAddr);

        packURI = _packURI;
    }

    string public override versionRecipient = "2.2.0";

    function setTrustedForwarder(address _forwarder) public onlyOwner() {
        _setTrustedForwarder(_forwarder);
    }

    event Open(uint256 newTokenId);
    event PackResultDecided(uint16 tokenId);
    
    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    //address private viridianExchangeAddress;

    // Base URI
    string private _baseURIextended;

    modifier onlyAdmin() {
        require(admins[_msgSender()] == true);
            _;
    }
    
    function setWhitelist(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelist[addresses[i]] = numAllowedToMint;
        }
    }

    function setHashedTokenIds(uint256[] memory _hashedTokenIds, uint256 _minIndex, uint256 _maxIndex) external onlyOwner {
        for (uint256 i = _minIndex; i <= _maxIndex; i++) {
            hashedTokenIds[i] = _hashedTokenIds[i - 1];
        }
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

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) private {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    function _setTokenURIAdmin(uint256 tokenId, string memory _tokenURI) public virtual onlyAdmin() {
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

    function totalSupply() public view returns (uint256 n) {
        return numMinted.current();
    }

    function getNumOwnedNFTs() public view virtual returns (uint256) {
        uint256 numOwnedNFTs = 0;

        for (uint256 i = 1; i <= numMinted.current(); i++) {
            if (_exists(i)) {
                if (ownerOf(i) == _msgSender()) {
                    numOwnedNFTs++;
                }
            }
        }

        return numOwnedNFTs;
    }
 
    ///TODO: This doesn't work with new tokenId system, maybe convert it back to old system to make it work again
    function getOwnedNFTs() public view virtual returns (uint256[] memory) {

        uint256[] memory _tokens = new uint256[](getNumOwnedNFTs());

        uint256 curIndex = 0;

        for (uint256 i = 1; i <= numMinted.current(); i++) {
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

    function setWhitelistMinting(bool _allowed) external onlyOwner() {
        allowWhitelistMinting = _allowed;
    }

    function setPublicMinting(bool _allowed) external onlyOwner() {
        allowPublicMinting = _allowed;
    }

    function isWhitelistMintingEnabled() public view returns (bool) {
        return allowWhitelistMinting;
    }

    function isPublicMintingEnabled() public view returns (bool) {
        return allowPublicMinting;
    }

    function append(string memory a, string memory b, string memory c) internal pure returns (string memory) {

        return string(abi.encodePacked(a, b, c));

    }

    function mint(
        uint8 _numMint,
        address _to
    ) public payable {
        require((totalSupply() + _numMint) <= maxMinted, "Mint amount is causing total supply to exceed 2000");
        require((allowWhitelistMinting && _whitelist[_to] > 0) || 
                allowPublicMinting, "Minting not enabled or not on whitelist");

        require(_numMint != 0, 'Cannot mint 0 nfts.');

        //TODO: Remove this after testing
        require(_numMint * 100000000000000000 == msg.value, "Must send correct amount of ETH to treasury address.");
        (payable(owner())).transfer(msg.value);

        //TODO: Add sending WETH

        for (uint256 i; i < _numMint; i++) {
            numMinted.increment();
            uint256 _tokenId = numMinted.current();

            string memory tokenURI_ = append(packURI, Strings.toString(_tokenId), "");

            _safeMint(_to, hashedTokenIds[_tokenId]);
            _setTokenURI(hashedTokenIds[_tokenId], tokenURI_);
        }
    }

    function compareStrings(string memory _s, string memory _s1) public pure returns (bool) {
        return (keccak256(abi.encodePacked((_s))) == keccak256(abi.encodePacked((_s1))));
    }

    function allowOpening() public onlyOwner() {
        openingLocked = false;
    }

    function freezeOpening() public onlyOwner() {
        openingLocked = true;
    }

    function isOpeningLocked() public view returns (bool) {
        return openingLocked;
    }

    function openPack(uint256 _tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), _tokenId));
        require(!openingLocked, "Opening is not alllowed yet");

        vNFT.mintFromPack(_msgSender(), _tokenId);

        _burn(_tokenId);

        emit Open(_tokenId);
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId));

        _burn(tokenId);
    }
}