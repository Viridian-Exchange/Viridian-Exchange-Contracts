// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract ViridianNFT is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;
    mapping(string => uint8) hashes;
    bool private initialized;
    mapping(address => bool) admins;

    function initialize() initializer public  {
        require(!initialized, "Contract instance has already been initialized");
        __ERC721_init("Viridian NFT", "VNFT");
        initialized = true;
    }

    using StringsUpgradeable for uint256;

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }



    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURIextended;

    modifier onlyAdmin() {
        require(admins[_msgSender()] == true);
            _;
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    ) public view override(ERC721Upgradeable) returns (bool isOperator) {
       if (admins[_msgSender()]) {
            return true;
        }
        // otherwise, use the default ERC721.isApprovedForAll()
        return super.isApprovedForAll(_owner, _operator);
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
        string memory tokenURI_ = StringsUpgradeable.toString(_tokenId);

        _safeMint(_to, _tokenId);
        _setTokenURI(_tokenId, tokenURI_);
    }

    function mintFromPack(
        address _to,
        uint256 _tokenId
    ) external onlyAdmin() {
        string memory _bUri = _baseURIextended;
        string memory tokenURI_ = StringsUpgradeable.toString(_tokenId);

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
