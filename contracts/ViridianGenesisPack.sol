// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

//import "./ViridianNFT.sol";


contract ViridianGenesisNFT is ERC721A, Ownable, BaseRelayRecipient {

    using Counters for Counters.Counter;
    Counters.Counter private numMinted;
    Counters.Counter private fingerprintIndex;

    bool private openingLocked = true;
    bool private allowWhitelistMinting = false;
    bool private allowPublicMinting = false;

    mapping(address => uint8) private _whitelist;

    uint256 public mintPrice = 200000000000000000;

    uint256 public maxMintAmt = 2000;

    mapping(uint256 => bool) public isOpened;

    mapping(uint256 => uint256) private hashedTokenIds;

    mapping(uint256 => uint256) private intermHashMap;

    mapping(address => bool) admins;

    address public viridianNFTAddr;

    address payable treasury;

    address erc20Addr;

    using Strings for uint256;

    constructor(address _forwarder, address payable _treasury, string memory _packURI, string memory _openURI) ERC721A("Viridian Genesis NFT", "VG") {

        _setTrustedForwarder(_forwarder);

        _baseURIextended = _packURI;
        _baseURIextendedOpened = _openURI;

        treasury = _treasury;
    }

    string public override versionRecipient = "2.2.0";

    function setTrustedForwarder(address _forwarder) public onlyOwner() {
        _setTrustedForwarder(_forwarder);
    }

    event Open(uint256 newTokenId);
    event PackResultDecided(uint16 tokenId);
    event Mint(address to);
    
    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    //address private viridianExchangeAddress;

    // Base URI
    string private _baseURIextended;
    string private _baseURIextendedOpened;

    modifier onlyAdmin() {
        require(admins[_msgSender()] == true);
            _;
    }

    function setERC20Addr(address payable _newERC20) external onlyOwner() {
        erc20Addr = _newERC20;
    }

    function setTreasury(address payable _newTreasury) external onlyOwner() {
        treasury = _newTreasury;
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

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        if (admins[_msgSender()]) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
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

    function setBaseURIOpened(string memory baseURI_) external onlyAdmin() {
        _baseURIextendedOpened = baseURI_;
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

    function _baseURIOpened() internal view virtual returns (string memory) {
        return _baseURIextendedOpened;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI;
        string memory base;
        
        if (isOpened[tokenId]) {
            base = _baseURIOpened();
        }
        else {
            base = _baseURI();
            _tokenURI = _tokenURIs[tokenId];
        }
        
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

    // function totalSupply() public view returns (uint256 n) {
    //     return numMinted.current();
    // }
 
    ///TODO: This doesn't work with new tokenId system, maybe convert it back to old system to make it work again
    function getOwnedNFTs() public view virtual returns (uint256[] memory) {

        uint256[] memory _tokens = new uint256[](balanceOf(_msgSender()));

        uint256 curIndex = 0;

        for (uint256 i = 1; i <= numMinted.current(); i++) {
            if (_exists(hashedTokenIds[i])) {
                if (ownerOf(hashedTokenIds[i]) == _msgSender()) {
                    _tokens[curIndex] = hashedTokenIds[i];
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

    function isAddressWhitelisted(address _addr) external view returns (bool) {
        return _whitelist[_addr] > 0;
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

    function convenienceFee() private view returns (uint256) {
        return mintPrice / 8;
    }

    function append(string memory a, string memory b, string memory c) internal pure returns (string memory) {

        return string(abi.encodePacked(a, b, c));
    }

    function setMintPrice(uint256 _newMintPrice) external onlyOwner() {
        mintPrice = _newMintPrice;
    }

    function mint(
        uint8 _numMint,
        address _to
    ) public payable {
        require((_totalMinted() + _numMint) <= maxMintAmt, "Mint amount is causing total supply to exceed 2000");
        require((allowWhitelistMinting && _whitelist[_to] > 0) || 
                allowPublicMinting, "Minting not enabled or not on whitelist");

        require(_numMint != 0, 'Cannot mint 0 nfts.');

        //TODO: Remove this after testing
        require(_numMint * mintPrice == msg.value, "Must pay correct amount of ETH to mint.");
        (payable(treasury)).transfer(msg.value);


        for (uint256 i; i < _numMint; i++) {
            uint256 _tokenId = _nextTokenId();

            string memory tokenURI_ = Strings.toString(_tokenId);

            _safeMint(_to, hashedTokenIds[_tokenId]);
            _setTokenURI(hashedTokenIds[_tokenId], tokenURI_);
        }

        //emit Mint(_to);
    }

    function crossmintMint(
        uint8 _numMint,
        address _to
    ) public payable {
        require((_totalMinted() + _numMint) <= maxMintAmt, "Mint amount is causing total supply to exceed 2000");
        require((allowWhitelistMinting && _whitelist[_to] > 0) || 
                allowPublicMinting, "Minting not enabled or not on whitelist");

        require(_numMint != 0, 'Cannot mint 0 nfts.');

        //TODO: Remove this after testing
        require(_numMint * (mintPrice + convenienceFee()) == msg.value, "Must pay correct amount of ETH to mint.");
        (payable(treasury)).transfer(msg.value);


        for (uint256 i; i < _numMint; i++) {
            numMinted.increment();
            uint256 _tokenId = numMinted.current();

            string memory tokenURI_ = Strings.toString(_tokenId);

            _safeMint(_to, hashedTokenIds[_tokenId]);
            _setTokenURI(hashedTokenIds[_tokenId], tokenURI_);
        }

        //emit Mint(_to);
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

    function open(uint256 _tokenId) public {
        bool isApprovedOrOwner = (_msgSender() == ownerOf(_tokenId) ||
                isApprovedForAll(ownerOf(_tokenId), _msgSender()));
        require(isApprovedOrOwner, "Caller is not approved or owner");
        require(!openingLocked, "Opening is not alllowed yet");

        isOpened[_tokenId] = true;

        emit Open(_tokenId);
    }

    function openTo(uint256 _tokenId, address _to) public {
        bool isApprovedOrOwner = (_msgSender() == ownerOf(_tokenId) ||
                isApprovedForAll(ownerOf(_tokenId), _msgSender()));
        require(isApprovedOrOwner, "Caller is not approved or owner");
        require(!openingLocked, "Opening is not alllowed yet");

        isOpened[_tokenId] = true;

        safeTransferFrom(_msgSender(), _to, _tokenId);

        emit Open(_tokenId);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId, true);
    }
}