pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

import "./RandomNumberGP.sol";
import "./ViridianNFT.sol";

contract ViridianGenesisPack is ERC721, Ownable, BaseRelayRecipient {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _unmintedTokenIds;
    mapping(string => uint8) hashes;
    mapping(uint256 => bool) private _tokensListed;
    string[] unmintedURIs;

    mapping(uint256 => bool) private packResultDecided;

    mapping(address => bool) admins;

    uint256 numNFTsInPacks;

    address public viridianNFTAddr;

    ViridianNFT vNFT;
    RandomNumberConsumerGenesis vrf;

    using Strings for uint256;

    constructor(address _viridianNFT, address _forwarder, uint256 _numNFTsInPacks) ERC721("Viridian Genesis Pack", "VGP") {

        require(address(_viridianNFT) != address(0));

        viridianNFTAddr = _viridianNFT;

        _setTrustedForwarder(_forwarder);

        vNFT = ViridianNFT(viridianNFTAddr);

        admins[_msgSender()] = true;

        numNFTsInPacks = _numNFTsInPacks;
    }

    string public override versionRecipient = "2.2.0";

    function setTrustedForwarder(address _forwarder) public onlyOwner() {
        _setTrustedForwarder(_forwarder);
    }

    event Open(string[10] newUris);
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

    function softMintNFT(string memory uri) public onlyAdmin() {
        unmintedURIs.push(uri);
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

    function isListed(uint256 tokenId) public view returns (bool) {
        return _tokensListed[tokenId];
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

    function compareStrings(string memory _s, string memory _s1) public pure returns (bool) {
        return (keccak256(abi.encodePacked((_s))) == keccak256(abi.encodePacked((_s1))));
    }

    function configureVRF(address _vrfAddress) public {
        vrf = RandomNumberConsumerGenesis(_vrfAddress);
    }

    function lockInPackResult(uint256 _tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not approved or owner");
        require(!packResultDecided[_tokenId], "Viridian Pack: Cannot redo pack result");
        packResultDecided[_tokenId] = true;
        vrf.getRandomNumber(_tokenId);

        emit PackResultDecided(_tokenId);
    }

    function isPackResultDecided(uint256 _tokenId) public view returns (bool) {
        return packResultDecided[_tokenId];
    }

    function openPack(uint256 _tokenId) public {
        // Randomly 
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Viridian Pack: must be approved or owner to open");
        require(packResultDecided[_tokenId], "Viridian Pack: pack result not decided yet");

        uint256[3] memory randRes = vrf.getRandomResultForToken(_tokenId);

        //require(rawRandRes > 0, "Viridian Pack: VRF hasn't generated random raw result yet");
        require(randRes[0] > 0, "Viridian Pack: VRF hasn't generated random result yet");
        require(randRes[1] > 0, "Viridian Pack: VRF hasn't generated random result yet");
        require(randRes[2] > 0, "Viridian Pack: VRF hasn't generated random result yet");

        string[10] memory newUris;

        // Need to delete the item from the unmintedNFTs minting happens again
        // Loop through the number of NFTs in the packs and then mint each random result
        for (uint8 n = 0; n < numNFTsInPacks; n++) {
        
            string memory newURI = unmintedURIs[randRes[n]];

            vNFT.mint(_msgSender(), newURI);

            newUris[randRes[n]] = newURI;
        
            string[] memory unmintedURIsCopy = unmintedURIs;

            for (uint i = 0; i < unmintedURIs.length; i++) {
                string memory uri = unmintedURIs[i];
                if (compareStrings(uri, newURI)) {
                    unmintedURIsCopy[i] = unmintedURIsCopy[unmintedURIsCopy.length - 1];
                    unmintedURIs = unmintedURIsCopy;
                    unmintedURIs.pop();
                    break;
                }
            }

            vrf.setMaxRange(unmintedURIs.length);
        }

        burn(_tokenId);

        emit Open(newUris);
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId));

        _burn(tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        require(!_tokensListed[tokenId], "Viridian NFT: Cannot transfer while listed on Viridian Exchange");
        require(!packResultDecided[tokenId], "Viridian NFT: Can only open pack once result is decided");

        super.safeTransferFrom(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(!_tokensListed[tokenId], "Viridian NFT: Cannot transfer while listed on Viridian Exchange");
        require(!packResultDecided[tokenId], "Viridian NFT: Can only open pack once result is decided");

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