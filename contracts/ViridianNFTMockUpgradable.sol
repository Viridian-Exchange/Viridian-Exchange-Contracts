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
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
* Viridian NFT
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

    mapping(address => uint256) private _whitelist;

    // Default number of NFTs that can be minted in the Genesis drop
    uint256 public maxMintAmt;

    // Default cost for minting one NFT in the Genesis drop
    uint256 public mintPrice;

    uint256 private coinConvRate;

    // ERC20 address for ERC20 mint
    address ERC20Addr;

    // Mapping for determining whether an unrevealed pack has been opened yet
    mapping(uint256 => bool) public isOpened;

    // All tokenIds derived from proof of integrity hashes that will be used in the geneis mint (Should have a length of 2000 before the mint starts)
    mapping(uint256 => uint256) private hashedTokenIds;

    // All admin addresses, primarily the exchange contracts
    mapping(address => bool) admins;

    // Treasury address where minting payments are sent
    address payable public treasury;

    string public override versionRecipient;

    address crossChainForwarder;

    using StringsUpgradeable for uint256;

    /**
     * @dev Set the original default opened and unopenend base URI. Also set the forwarder for gaseless and the treasury address.
     */
     function initialize(address _forwarder, address _crossChainForwarder, address payable _treasury, address _ERC20Addr, string memory _packURI, string memory _openURI, uint256 _coinConvRate) public initializer {
        __ERC721_init("Viridian NFT", "VNFT");
        __ERC721Enumerable_init();
        __Ownable_init();
        _setTrustedForwarder(_forwarder);
        crossChainForwarder = _crossChainForwarder;
        ERC20Addr = _ERC20Addr;

        dropId.increment();
        uint256 _dropId = dropId.current();

        _baseURIextended[_dropId] = _packURI;
        _baseURIextendedOpened[_dropId] = _openURI;
        treasury = _treasury;

        allowWhitelistMinting = false;
        allowPublicMinting = false;
        maxMintAmt = 2000;
        mintPrice = 200000000000000000;
        coinConvRate = _coinConvRate;
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
    function newDrop(uint256 _numMints, uint256 _mintPrice, string memory _newUnrevealedBaseURI, string memory _newRevealedBaseURI) external onlyOwner() {
        maxMintAmt = _numMints + numMinted.current();

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
     * @dev Change the conversion rate from ERC20 token to native coin.
     */
    function setConvRate(uint256 _newConvRate) external onlyOwner() {
        coinConvRate = _newConvRate;
    }

    /**
     * @dev View the price to mint in native coin
     */
    function coinMintPrice() external view onlyOwner() returns (uint256) {
        return coinConvRate * mintPrice;
    }


    /**
     * @dev Owner can set the whitelist addresses and how many NFTs each whitelist member can mint.
     */
    function setWhitelist(address[] calldata addresses, uint256 numAllowedToMint, uint256 startIndex) external onlyOwner {
        for (uint256 i = startIndex; i < addresses.length; i++) {
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

    /**
     * @dev Overridden version of isApprovedForAll where the admins (exchange addresses) are always approved
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        if (admins[operator]) {
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
        _baseURIextended[dropId.current()] = baseURI_;
    }

    /**
     * @dev Admin can change base URI for openend NFTs.
     */
    function setBaseURIOpened(string memory baseURI_) external onlyAdmin() {
        _baseURIextendedOpened[dropId.current()] = baseURI_;
    }

    /**
     * @dev Admin can change base URI for unopened NFTs.
     */
    function setBaseURI(string memory baseURI_, uint256 _dropId) external onlyAdmin() {
        _baseURIextended[_dropId] = baseURI_;
    }

    /**
     * @dev Admin can change base URI for openend NFTs.
     */
    function setBaseURIOpened(string memory baseURI_, uint256 _dropId) external onlyAdmin() {
        _baseURIextendedOpened[_dropId] = baseURI_;
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

        string memory base;

        if (isOpened[tokenId]) {
            base = _baseURIOpened(tokenDropId[tokenId]);
        }
        else {
            base = _baseURI(tokenDropId[tokenId]);
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

    function decrementWhitelistMintLimit(address _to, uint256 _numMinted) private {
        uint256 curWhitelistMintLimit = _whitelist[_to];
        uint256 decremented = curWhitelistMintLimit - _numMinted;

        _whitelist[_to] = decremented;
    }

    /**
     * @dev Admin addresses can manually mint NFTs either unrevealed or revealed. This will primarily be used for getting submissions onto the exchange.
     */
    function adminMint(
        uint256[] calldata _tokenIds,
        uint256 _dropId,
        address _to,
        bool opened
    ) public payable onlyAdmin() {
        require(_tokenIds.length != 0, 'Cannot mint 0 nfts.');

        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];

            if (opened) {
                isOpened[_tokenId] = true;
            }

            _safeMint(_to, hashedTokenIds[_tokenId]);
            tokenDropId[_tokenId] = _dropId;
        }
    }

    function _handleMint(uint256 _numMint, address _to, bool _erc20, bool _crosschain) private {
        require((numMinted.current() + _numMint) <= maxMintAmt, "Mint amount is causing total supply to exceed 2000");

        require((allowWhitelistMinting && (_whitelist[_to] > 0 && _numMint <= _whitelist[_to])) || 
                allowPublicMinting, "Minting not enabled or not on lists / minting over list limits");

        require(_numMint != 0, 'Cannot mint 0 nfts.');

        if (_whitelist[_to] > 0) {
            decrementWhitelistMintLimit(_to, _numMint);
        }
        else if (allowPublicMinting || _whitelist[_to] > 0) {
            if (_erc20)  {
                require(_numMint * mintPrice <= IERC20(ERC20Addr).balanceOf(_msgSender()), "Must have enought ERC20 token to mint.");
                IERC20(ERC20Addr).transfer(treasury, _numMint * mintPrice);
            }
            else if (!_erc20) {
                require((_numMint * mintPrice) * coinConvRate == msg.value, "Must pay correct amount of ETH to mint.");
                (payable(treasury)).transfer(msg.value);
            }
            else if (_crosschain) {
                require(_msgSender() == crossChainForwarder, "Only approved forwarder can call crosschain mint");
                require(0 != msg.value, "Must recieve any amount from crosschain provider.");
            }
        }

        for (uint256 i; i < _numMint; i++) {
            numMinted.increment();
            uint256 _tokenId = numMinted.current();

            _safeMint(_to, _tokenId);
            tokenDropId[_tokenId] = dropId.current();
        }
    }

    function mint(
        uint256 _numMint,
        address _to
    ) public payable {
        _handleMint(_numMint, _to, false, false);
    }

    /**
     * @dev Users can mint during the drop using the blockchains native currency (ex: Ether on Ethereum).
     */
    function ERC20Mint(
        uint256 _numMint,
        address _to
    ) public payable {
        _handleMint(_numMint, _to, true, false);
    }

    /**
     * @dev Users can mint with USD on crossmint during the drop.
     */
    function crossChainMint(
        uint256 _numMint,
        address _to
    ) public payable {
         _handleMint(_numMint, _to, false, true);
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

        burn(_tokenId);
        _safeMint(_msgSender(), hashedTokenIds[_tokenId]);

        isOpened[hashedTokenIds[_tokenId]] = true;

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

        burn(_tokenId);
        _safeMint(_to, hashedTokenIds[_tokenId]);

        isOpened[hashedTokenIds[_tokenId]] = true;

        emit Open(_tokenId);
    }

    /**
     * Destroy the NFT with the given token Id.
     */
    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }
}
