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

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

/**
* Viridian Genesis NFT
*
* This contract is designed to be used on our genesis Ethereum mint and future drops on the same contract, it is extremely gas efficient for minting multiple packs.
*
* If this contract can be upgradable and/or be upgradable it could be converted to our main infrastructure contract.
*/
contract ViridianNFTMockUpgradable is Initializable, ERC721EnumerableUpgradeable, OwnableUpgradeable, BaseRelayRecipient {

    // Keeps track of the current minted NFT for setting the pack URI correctly
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private numMinted;
    CountersUpgradeable.Counter private dropId;

    mapping(uint256 => uint256) private tokenDropId;

    // Mint and Opening control booleans
    mapping(uint256 => bool) private openingUnlocked;
    bool private allowWhitelistMinting;
    bool private allowPublicMinting;

    mapping(address => uint8) private _whitelist;

    // Default number of NFTs that can be minted in the Genesis drop
    uint16 public maxMintAmt;

    // Default cost for minting one NFT in the Genesis drop
    uint256 public mintPrice;

    // Mapping for determining whether an unrevealed pack has been opened yet
    mapping(uint256 => bool) public isOpened;

    // All tokenIds derived from proof of integrity hashes that will be used in the geneis mint (Should have a length of 2000 before the mint starts)
    mapping(uint256 => uint256) private hashedTokenIds;

    // All admin addresses, primarily the exchange contracts
    mapping(address => bool) admins;

    // Treasury address where minting payments are sent
    address payable public treasury;

    string public override versionRecipient;

    using StringsUpgradeable for uint256;

    /**
     * @dev Set the original default opened and unopenend base URI. Also set the forwarder for gaseless and the treasury address.
     */
     function initialize(address _forwarder, address payable _treasury, string memory _packURI, string memory _openURI) public initializer  {
        /* require(!initialized, "Contract instance has already been initialized"); */
        __ERC721_init("Viridian NFT", "VNFT");
        __ERC721Enumerable_init();
        __Ownable_init();
        _setTrustedForwarder(_forwarder);

        dropId.increment();
        uint256 _dropId = dropId.current();

        _baseURIextended[_dropId] = _packURI;
        _baseURIextendedOpened[_dropId] = _openURI;
        treasury = _treasury;

        allowWhitelistMinting = false;
        allowPublicMinting = false;
        maxMintAmt = 2000;
        mintPrice = 200000000000000000;
        versionRecipient = "2.2.0";
    }

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
    mapping (uint256 => string) private _baseURIextended;

    // Base URI for opened NFTs
    mapping (uint256 => string) private _baseURIextendedOpened;

    // Enfornces only admins calling a function
    modifier onlyAdmin() {
        require(admins[_msgSender()] == true);
            _;
    }

    /**
     * @dev Start a new drop while leaving the previous drops alone.
     */
    function newDrop(uint16 _numMints, uint256 _mintPrice, string memory _newUnrevealedBaseURI, string memory _newRevealedBaseURI) external onlyOwner() {
        numMinted.reset();
        maxMintAmt = _numMints;

        dropId.increment();
        uint256 _dropId = dropId.current();

        _baseURIextended[_dropId] = _newUnrevealedBaseURI;
        _baseURIextendedOpened[_dropId] = _newRevealedBaseURI;

        mintPrice = _mintPrice;
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
            tokenDropId[_hashedTokenIds[i - 1]] = dropId.current();
        }
    }

    /**
     * @dev Replaces msg.sender for gasless support.
     */
    function _msgSender() internal view override(ContextUpgradeable, BaseRelayRecipient) returns (address sender) {
        sender = BaseRelayRecipient._msgSender();
    }

    /**
     * @dev Replaces msg.data for gasless support.
     */
    function _msgData() internal view override(ContextUpgradeable, BaseRelayRecipient) returns (bytes calldata) {
        return BaseRelayRecipient._msgData();
    }

    // /**
    //  * @dev Overridden version of isApprovedForAll where the admins (exchange addresses) are always approved
    //  */
    // function isApprovedForAll(address owner, address operator) public view override(ERC721Upgradeable) returns (bool) {
    //     if (admins[_msgSender()]) {
    //         return true;
    //     }

    //     return super.isApprovedForAll(owner, operator);
    // }

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
        _baseURIextended[dropId.current()] = baseURI_;
    }

    /**
     * @dev Admin can change base URI for openend NFTs.
     */
    function setBaseURIOpened(string memory baseURI_) external onlyAdmin() {
        _baseURIextendedOpened[dropId.current()] = baseURI_;
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
    function _baseURI(uint256 _dropId) internal view virtual returns (string memory) {
        return _baseURIextended[_dropId];
    }

    /**
     * @dev Returns the baseURI for opened NFTs.
     */
    function _baseURIOpened(uint256 _dropId) internal view virtual returns (string memory) {
        return _baseURIextendedOpened[_dropId];
    }

    /**
     * Returns the token URI which will be different dependent on whether the NFT has been opened.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI;
        string memory base;

        if (isOpened[tokenId]) {
            base = _baseURIOpened(tokenDropId[tokenId]);
        }
        else {
            base = _baseURI(tokenDropId[tokenId]);
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

    function decrementWhitelistMintLimit(address _to, uint8 _numMinted) private {
        uint8 curWhitelistMintLimit = _whitelist[_to];

        // (2-1) - 1 == 0 // | (3-1) - 1 = 1
        uint8 decremented = (curWhitelistMintLimit - 1) - _numMinted;

        _whitelist[_to] = decremented;
    }

    /**
     * @dev Admin addresses can manually mint NFTs either unrevealed or revealed. This will primarily be used for getting submissions onto the exchange.
     */
    function adminMint(
        uint256[] calldata _tokenIds,
        address _to,
        bool opened
    ) public payable onlyAdmin() {
        require(_tokenIds.length != 0, 'Cannot mint 0 nfts.');

        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];

            if (opened) {
                isOpened[_tokenId] = true;
            }

            string memory tokenURI_ = StringsUpgradeable.toString(_tokenId);

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
        require((numMinted.current() + _numMint) <= maxMintAmt, "Mint amount is causing total supply to exceed 2000");
        

        // If a user is given a whitelist limit of 1 they can mint for free once.
        require((allowWhitelistMinting && _whitelist[_to] > 0) || 
                allowPublicMinting, "Minting not enabled or not on whitelist / trying to mint more than allowed by the whitelist");
        require(_numMint != 0, 'Cannot mint 0 nfts.');

        // Every whitelist limit above 1 has to pay to mint and they can mint the whitelist limit - 1.
        if (allowPublicMinting) {
            require(_numMint * mintPrice == msg.value, "Must pay correct amount of ETH to mint.");
            (payable(treasury)).transfer(msg.value);
        }
        else if (_whitelist[_to] > 1) {
            require((_numMint <= (_whitelist[_to] - 1)), "Cannot mint more NFTs than your whitelist limit");
            require(_numMint * mintPrice == msg.value, "Must pay correct amount of ETH to mint.");
            (payable(treasury)).transfer(msg.value);

            decrementWhitelistMintLimit(_to, _numMint);
        }
        else {
            _whitelist[_to] = 0;
        }


        for (uint256 i; i < _numMint; i++) {
            numMinted.increment();
            uint256 _tokenId = numMinted.current();

            string memory tokenURI_ = StringsUpgradeable.toString(_tokenId);

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
        require((numMinted.current() + _numMint) <= maxMintAmt, "Mint amount is causing total supply to exceed 2000");

        // If a user is given a whitelist limit of 1 they can mint for free once.
        require((allowWhitelistMinting && _whitelist[_to] > 0) || 
                allowPublicMinting, "Minting not enabled or not on whitelist / trying to mint more than allowed by the whitelist");

        require(_numMint != 0, 'Cannot mint 0 nfts.');

        // Every whitelist limit above 1 has to pay to mint and they can mint the whitelist limit - 1.
        if (allowPublicMinting) {
            require(_numMint * (mintPrice + convenienceFee()) == msg.value, "Must pay correct amount of ETH to mint.");
            (payable(treasury)).transfer(msg.value);
        }
        else if (_whitelist[_to] > 1) {
            require((_numMint <= (_whitelist[_to] - 1)), "Cannot mint more NFTs than your whitelist limit");
            require(_numMint * (mintPrice + convenienceFee()) == msg.value, "Must pay correct amount of ETH to mint.");
            (payable(treasury)).transfer(msg.value);

            decrementWhitelistMintLimit(_to, _numMint);
        }
        else {
            _whitelist[_to] = 0;
        }


        for (uint256 i; i < _numMint; i++) {
            numMinted.increment();
            uint256 _tokenId = numMinted.current();

            string memory tokenURI_ = StringsUpgradeable.toString(_tokenId);

            _safeMint(_to, hashedTokenIds[_tokenId]);
            _setTokenURI(hashedTokenIds[_tokenId], tokenURI_);
        }
    }

    /**
     * @dev Enables users to be able to open their NFTs.
     */
    function allowOpening() public onlyOwner() {
        openingUnlocked[dropId.current()] = true;
    }

    /**
     * @dev Disables the ability to open NFTs.
     */
    function freezeOpening() public onlyOwner() {
        openingUnlocked[dropId.current()] = false;
    }

    /**
     * @dev Returns whether users are able to open their NFTs.
     */
    function isOpeningUnlocked() public view returns (bool) {
        return openingUnlocked[dropId.current()];
    }

    /**
     * @dev Returns whether users are able to open their NFTs.
     */
    function isTokenOpeningUnlocked(uint256 _tokenId) public view returns (bool) {
        return openingUnlocked[tokenDropId[_tokenId]];
    }

    /**
     * @dev Allows user to open an NFT and reveal the contents.
     */
    function open(uint256 _tokenId) public {
        bool isApprovedOrOwner = (_msgSender() == ownerOf(_tokenId) ||
                isApprovedForAll(ownerOf(_tokenId), _msgSender()));
        require(isApprovedOrOwner, "Caller is not approved or owner");
        require(isTokenOpeningUnlocked(_tokenId), "Opening is not alllowed yet");

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
        require(isTokenOpeningUnlocked(_tokenId), "Opening is not alllowed yet");

        isOpened[_tokenId] = true;

        safeTransferFrom(_msgSender(), _to, _tokenId);

        emit Open(_tokenId);
    }

    /**
     * Destroy the NFT with the given token Id.
     */
    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }
}
