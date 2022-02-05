pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

contract ViridianPass is ERC721, Ownable, BaseRelayRecipient {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(string => uint8) hashes;
    
    mapping(address => bool) admins;
    address treasury;
    string defaultURI;

    constructor(string memory _defaultURI, address _forwarder) ERC721("Viridian 1st Edition Pass", "V1EP") {
        _setTrustedForwarder(_forwarder);
        treasury = payable(_msgSender());
        admins[_msgSender()] = true;
        defaultURI = _defaultURI;
    }

    string public override versionRecipient = "2.2.0";

    function setTrustedForwarder(address _forwarder) public onlyOwner() {
        _setTrustedForwarder(_forwarder);
    }

    using Strings for uint256;


    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURIextended;

    modifier onlyAdmin() {
        require(admins[_msgSender()] == true);
            _;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
        if (admins[_msgSender()]) {
            return true;
        }

        return super._isApprovedOrOwner(spender, tokenId);
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
    
    function setBaseURI(string memory baseURI_) external onlyAdmin() {
        _baseURIextended = baseURI_;
    }

    function setDefaultURI(string memory _defURI) public onlyAdmin() {
        defaultURI = _defURI;
    }
    
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) private {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Must be owner or admin to change tokenURI");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _setTokenURIAdmin(uint256 tokenId, string memory _tokenURI) public virtual onlyAdmin() {
        _setTokenURI(tokenId, _tokenURI);
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

    function mint(uint numMint) external payable {
        require(numMint != 0, 'Cannot mint 0 nfts.');
        require(1000000000000000000 * numMint == msg.value, "Must send correct amount of ETH to treasury address.");
        (payable(treasury)).transfer(msg.value);
        require(_tokenIds.current() + numMint <= 396, 'Minting over the pass limit');

        for (uint i = 0; i < numMint; i++) {
            _tokenIds.increment();
            uint256 _tokenId = _tokenIds.current();
            require(_tokenId <= 396, 'All passes have been minted.');

            _safeMint(_msgSender(), _tokenId);
            _setTokenURI(_tokenId, defaultURI);
        }
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId));

        _burn(tokenId);
    }

    function bridge(uint256[] memory _bridgeTokenIds) public {
        for (uint256 i = 0; i < _bridgeTokenIds.length; i++) {
            require(_isApprovedOrOwner(_msgSender(), _bridgeTokenIds[i]));

            _burn(_bridgeTokenIds[i]);
        }
    }
}