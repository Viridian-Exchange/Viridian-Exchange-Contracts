// SPDX-License-Identifier: MIT

/**
 *****    .*****************************************     *****.                                                                                                                                         
  *****     ***************************************    .*****                                                                                                                                           
   ******    ******                                   ******                                                                                                                                            
     *****     *****                                ******        ***       ****    ***,      **********      ****      ***********       .***         .***          ***       ***                      
      ******    ******                             *****           ***.    ****     ***,      ***     ***.    ****      ***      ****     .***        ******         *****     ***                      
        *****     **************************,    ******             ***,  ***       ***,      ***    ****     ****      ***       ****    .***       **** ***        *** ****  ***                      
         ,*****    ************************     *****                *******        ***,      ********.       ****      ***       ***     .***      ***,   ***       ***   *******                      
           *****     *****                    ******                  *****         ***,      ***   ***,      ****      ***     ****,     .***     ************      ***     *****                      
            ,*****    ******                ,*****                     .**          ***,      ***    ****     ****      **********        .***    ***        ***     ***       ***                      
              *****     ******             ******                                                                                                                                                       
                *****     ***********    ,*****                                                                                                                                                         
                 ******    ********     ******                                                                                                                                                          
                   *****     *****    ******                       **********     ****    ****      ,**********     ***       ***.          **.          **        ***        **********      **********
                    ******    **     *****                         ***.            **** ****      .****      *      ***       ***.        .****,         *****     ***      ****      *,      ***.      
                      *****        ******                          *********         ******       ***               *************.       ,*******        *******   ***     ****               ********* 
                       .*****     *****                            *********         ******       ***               *************.      ****  ****       ***  ********     ***.     *****     ********* 
                         *****. ******                             ***.            **** ****      ****.             ***       ***.     ************      ***     *****      ****      ***     ***.      
                          .*********                               **********     ****    ****      ***********     ***       ***.    ***.       ***     ***       ***        ***********     **********
                            *******                                                                                                                                                                     
                              ***                                                                                                                                                                       
 */

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
* Viridian Genesis NFT
* 
* This contract is designed to be used on our genesis Ethereum mint, it is extremely gas efficient for minting multiple packs and potentially run multiple drops.
* 
* If this contract can be upgradable and/or be upgradable it could be converted to our main infrastructure contract.
*/
contract ViridianGenesisNFT is ERC721A, Ownable, BaseRelayRecipient {

    // Keeps track of the current minted NFT for setting the pack URI correctly
    using Counters for Counters.Counter;
    Counters.Counter private numMinted;

    // Mint and Opening control booleans
    bool private openingLocked = true;
    bool private allowWhitelistMinting = false;
    bool private allowPublicMinting = false;

    mapping(address => uint8) private _whitelist;

    // Default cost for minting one NFT in the Genesis drop
    uint256 public mintPrice = 200000000000000000;

    // Default number of NFTs that can be minted in the Genesis drop
    uint256 public maxMintAmt = 2000;

    // Mapping for determining whether an unrevealed pack has been opened yet
    mapping(uint256 => bool) public isOpened;

    // All tokenIds derived from proof of integrity hashes that will be used in the geneis mint (Should have a length of 2000 before the mint starts)
    mapping(uint256 => uint256) private hashedTokenIds;

    // All admin addresses, primarily the exchange contracts
    mapping(address => bool) admins;

    // Treasury address where minting payments are sent
    address payable treasury;

    using Strings for uint256;

    /**
     * @dev Set the original default opened and unopenend base URI. Also set the forwarder for gaseless and the treasury address.
     */
    constructor(address _forwarder, address payable _treasury, string memory _packURI, string memory _openURI) ERC721A("Viridian Genesis NFT", "VG") {

        _setTrustedForwarder(_forwarder);

        _baseURIextended = _packURI;
        _baseURIextendedOpened = _openURI;

        treasury = _treasury;
    }

    string public override versionRecipient = "2.2.0";

    /**
     * @dev Owner can change the trusted forwarder used for gasless.
     */
    function setTrustedForwarder(address _forwarder) public onlyOwner() {
        _setTrustedForwarder(_forwarder);
    }

    // Events for the pack opening experience
    event Open(uint256 newTokenId);
    event PackResultDecided(uint16 tokenId);
    
    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    //address private viridianExchangeAddress;

    // Base URI for unopened NFTs
    string private _baseURIextended;

    // Base URI for opened NFTs
    string private _baseURIextendedOpened;

    // Enfornces only admins calling a function
    modifier onlyAdmin() {
        require(admins[_msgSender()] == true);
            _;
    }

    /**
     * @dev Owner can change the treasury address.
     */
    function setTreasury(address payable _newTreasury) external onlyOwner() {
        treasury = _newTreasury;
    }
    
    /**
     * @dev Owner can set the whitelist addresses and how many NFTs each whitelist member can mint.
     */
    function setWhitelist(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelist[addresses[i]] = numAllowedToMint;
        }
    }

    /**
     * @dev Owner can set the hashed tokenIds.
     */
    function setHashedTokenIds(uint256[] memory _hashedTokenIds, uint256 _minIndex, uint256 _maxIndex) external onlyOwner {
        for (uint256 i = _minIndex; i <= _maxIndex; i++) {
            hashedTokenIds[i] = _hashedTokenIds[i - 1];
        }
    }

    /**
     * @dev Replaces msg.sender for gasless support.
     */
    function _msgSender() internal view override(Context, BaseRelayRecipient) returns (address sender) {
        sender = BaseRelayRecipient._msgSender();
    }

    /**
     * @dev Replaces msg.data for gasless support.
     */
    function _msgData() internal view override(Context, BaseRelayRecipient) returns (bytes memory) {
        return BaseRelayRecipient._msgData();
    }

    /**
     * @dev Overridden version of isApprovedForAll where the admins (exchange addresses) are always approved
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        if (admins[_msgSender()]) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev Owner can add new admins addresses if exchange is upgraded.
     */
    function addAdmin(address _newAdmin) external onlyOwner() {
        admins[_newAdmin] = true;
    }

    /**
     * @dev Owner can remove permissions from depreciated admin addresses.
     */
    function removeAdmin(address _newAdmin) external onlyOwner() {
        admins[_newAdmin] = false;
    }
    
    /**
     * @dev Admin can change base URI for unopened NFTs.
     */
    function setBaseURI(string memory baseURI_) external onlyAdmin() {
        _baseURIextended = baseURI_;
    }

    /**
     * @dev Admin can change base URI for openend NFTs.
     */
    function setBaseURIOpened(string memory baseURI_) external onlyAdmin() {
        _baseURIextendedOpened = baseURI_;
    }

    /**
     * @dev Changes the tokenURI.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) private {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Admin can change the tokenURI.
     */
    function _setTokenURIAdmin(uint256 tokenId, string memory _tokenURI) public virtual onlyAdmin() {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    
    /**
     * @dev Returns the baseURI for unopened NFTs.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /**
     * @dev Returns the baseURI for opened NFTs.
     */
    function _baseURIOpened() internal view virtual returns (string memory) {
        return _baseURIextendedOpened;
    }
    
    /**
     * Returns the token URI which will be different dependent on whether the NFT has been opened.
     */
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

    /**
     * Total existing supply of NFTs in circulation (Already integrated into ERC721A) 
     */
    // function totalSupply() public view returns (uint256 n) {
    //     return numMinted.current();
    // }
 
    //TODO: This doesn't work with new tokenId system, maybe convert it back to old system to make it work again
    /**
     * @dev Returns message senders owned NFTs as a list of token Ids.
     */
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

    /**
     * @dev Returns the addresses owned NFTs as a list of token Ids.
     */
    function getOwnedNFTs(address addr) public view virtual returns (uint256[] memory) {

        uint256[] memory _tokens = new uint256[](balanceOf(addr));

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

    /**
     * @dev Returns whether the address is on the whitelist.
     */
    function isAddressWhitelisted(address _addr) external view returns (bool) {
        return _whitelist[_addr] > 0;
    }

    /**
     * @dev Enables the ability for addresses on the whitelist to begin minting.
     */
    function setWhitelistMinting(bool _allowed) external onlyOwner() {
        allowWhitelistMinting = _allowed;
    }

    /**
     * @dev Enables the ability for any addresses to begin minting.
     */
    function setPublicMinting(bool _allowed) external onlyOwner() {
        allowPublicMinting = _allowed;
    }

    /**
     * @dev Returns whether the whitelist minting period has started.
     */
    function isWhitelistMintingEnabled() public view returns (bool) {
        return allowWhitelistMinting;
    }

    /**
     * @dev Returns whether the public minting period has started.
     */
    function isPublicMintingEnabled() public view returns (bool) {
        return allowPublicMinting;
    }

    /**
     * @dev Adjusted mint price convenience fee for mintign with USD.
     */
    function convenienceFee() private view returns (uint256) {
        return mintPrice / 8;
    }

    /**
     * @dev Appends three strings together. 
     */
    function append(string memory a, string memory b, string memory c) internal pure returns (string memory) {

        return string(abi.encodePacked(a, b, c));
    }

    /**
     * @dev Owner can change the mint price for one NFT.
     */
    function setMintPrice(uint256 _newMintPrice) external onlyOwner() {
        mintPrice = _newMintPrice;
    }

    /**
     * @dev Admin addresses can manually mint NFTs either unrevealed or revealed. This will primarily be used for getting submissions onto the exchange.
     */
    function mint(
        uint256[] calldata _tokenIds,
        address _to,
        bool opened
    ) public payable onlyAdmin() {
        require(_tokenIds.length != 0, 'Cannot mint 0 nfts.');

        //TODO: Remove this after testing
        require(_tokenIds.length * mintPrice == msg.value, "Must pay correct amount of ETH to mint.");
        (payable(treasury)).transfer(msg.value);


        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];

            if (opened) {
                isOpened[_tokenId] = true;
            }

            string memory tokenURI_ = Strings.toString(_tokenId);

            _safeMint(_to, hashedTokenIds[_tokenId]);
            _setTokenURI(hashedTokenIds[_tokenId], tokenURI_);
        }
    }

    /**
     * @dev Users can mint during the drop using the blockchains native currency (ex: Ether on Ethereum).
     */
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
            numMinted.increment();
            uint256 _tokenId = numMinted.current();

            string memory tokenURI_ = Strings.toString(_tokenId);

            _safeMint(_to, hashedTokenIds[_tokenId]);
            _setTokenURI(hashedTokenIds[_tokenId], tokenURI_);
        }
    }

    /**
     * @dev Users can mint with USD on crossmint during the drop for a convenience fee (ex: Ether on Ethereum).
     */
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
    }

    /**
     * @dev Enables users to be able to open their NFTs.
     */
    function allowOpening() public onlyOwner() {
        openingLocked = false;
    }

    /**
     * @dev Disables the ability to open NFTs.
     */
    function freezeOpening() public onlyOwner() {
        openingLocked = true;
    }

    /**
     * @dev Returns whether users are able to open their NFTs.
     */
    function isOpeningLocked() public view returns (bool) {
        return openingLocked;
    }

    /**
     * @dev Allows user to open an NFT and reveal the contents.
     */
    function open(uint256 _tokenId) public {
        bool isApprovedOrOwner = (_msgSender() == ownerOf(_tokenId) ||
                isApprovedForAll(ownerOf(_tokenId), _msgSender()));
        require(isApprovedOrOwner, "Caller is not approved or owner");
        require(!openingLocked, "Opening is not alllowed yet");

        isOpened[_tokenId] = true;

        emit Open(_tokenId);
    }

    /**
     * @dev Allows user to open an NFT and reveal the contents, then have it transferred to a different address.
     * This will be primarily used by streamers to open up packs their audience has purcahsed.
     */
    function openTo(uint256 _tokenId, address _to) public {
        bool isApprovedOrOwner = (_msgSender() == ownerOf(_tokenId) ||
                isApprovedForAll(ownerOf(_tokenId), _msgSender()));
        require(isApprovedOrOwner, "Caller is not approved or owner");
        require(!openingLocked, "Opening is not alllowed yet");

        isOpened[_tokenId] = true;

        safeTransferFrom(_msgSender(), _to, _tokenId);

        emit Open(_tokenId);
    }

    /**
     * Destroy the NFT with the given token Id.
     */
    function burn(uint256 tokenId) public {
        _burn(tokenId, true);
    }
}