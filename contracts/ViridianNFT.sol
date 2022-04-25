// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ViridianNFT is ERC721, Ownable, BaseRelayRecipient {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(string => uint8) hashes;
    
    mapping(address => bool) admins;

    constructor(address _forwarder) ERC721("Viridian NFT", "VNFT") {
        _setTrustedForwarder(_forwarder);
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

    function _msgSender() internal view override(Context, BaseRelayRecipient) returns (address sender) {
        sender = BaseRelayRecipient._msgSender();
    }

    function _msgData() internal view override(Context, BaseRelayRecipient) returns (bytes memory) {
        return BaseRelayRecipient._msgData();
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
       if (admins[_msgSender()]) {
            return true;
        }
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function addAdmin(address _newAdmin) external onlyOwner() {
        admins[_newAdmin] = true;
    }

    function removeAdmin(address _newAdmin) external onlyOwner() {
        admins[_newAdmin] = false;
    }
    
    function setBaseURI(string memory baseURI_) external onlyOwner() {
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

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function append(string memory a, string memory b, string memory c) internal pure returns (string memory) {

        return string(abi.encodePacked(a, b, c));

    }

    function mint(
        address _to,
        string memory _fingerprint
    ) external onlyAdmin() {
        uint256 _tokenId = uint256(keccak256(abi.encode(_fingerprint)));
        string memory _bUri = _baseURIextended;
        string memory tokenURI_ = Strings.toString(_tokenId);

        _safeMint(_to, _tokenId);
        _setTokenURI(_tokenId, tokenURI_);
    }

    function mintFromPack(
        address _to,
        uint256 _tokenId
    ) external onlyAdmin() {
        string memory _bUri = _baseURIextended;
        string memory tokenURI_ = Strings.toString(_tokenId);

        _safeMint(_to, _tokenId);
        _setTokenURI(_tokenId, tokenURI_);
    }

    function generateProofOfIntegrity(string memory base, uint256 salt) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(base, salt));
    }

    function verifyProofOfIntegrity(uint256 _tokenId, string memory base, uint256 salt) public pure returns (bool) {
        return bytes32(_tokenId) == generateProofOfIntegrity(base, salt);
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved to burn");

        _burn(tokenId);
    }
}