pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

import "./RandomNumber.sol";
import "./ViridianNFT.sol";

contract ViridianPack is ERC721, Ownable, BaseRelayRecipient {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _unmintedTokenIds;
    mapping(string => uint8) hashes;
    mapping(uint256 => mapping(uint256 => uint256)) private rarityOdds;
    mapping(uint256 => uint256) private numNFTs;
    //mapping(uint256 => string) private unmintedURIs;
    mapping(uint256 => bool) private _tokensListed;
    mapping(uint256 => uint256) tokenRarity;
    mapping(uint256 => string[]) private uriRarityPools;
    int private maxRarityIndex;

    mapping(uint256 => bool) private packResultDecided;

    mapping(address => bool) admins;

    address public viridianNFTAddr;

    ViridianNFT vNFT;
    RandomNumberConsumer vrf;

    using Strings for uint256;

    constructor(address _viridianNFT, address _forwarder) ERC721("Viridian Pack", "VP") {

        require(address(_viridianNFT) != address(0));

        viridianNFTAddr = _viridianNFT;

        _setTrustedForwarder(_forwarder);

        vNFT = ViridianNFT(viridianNFTAddr);

        //Set all beginning rarities

        // Legendary rarity and cards in pack
        rarityOdds[0][0] = 25;
        rarityOdds[0][1] = 100;
        rarityOdds[0][2] = 300;
        rarityOdds[0][3] = 1000;
        numNFTs[0] = 3;

        // Mystical rarity and cards in pack
        rarityOdds[1][0] = 1;
        rarityOdds[1][1] = 50;
        rarityOdds[1][2] = 200;
        rarityOdds[1][3] = 1000;
        numNFTs[0] = 3;

        // Rare rarity and cards in pack
        rarityOdds[2][0] = 0;
        rarityOdds[2][1] = 50;
        rarityOdds[2][2] = 100;
        rarityOdds[2][3] = 1000;
        numNFTs[0] = 3;

        // Common rarity and cards in pack
        rarityOdds[3][0] = 0;
        rarityOdds[3][1] = 10;
        rarityOdds[3][2] = 50;
        rarityOdds[3][3] = 1000;
        numNFTs[0] = 3;

        maxRarityIndex = 3;

        admins[_msgSender()] = true;
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

    function getUriRarityPools(uint256 _rarity) public view onlyAdmin() returns (string[] memory) {
        return uriRarityPools[_rarity];
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

    function setRarityOdds(uint256 _rarity, uint256 _rarityOdd, uint256 _newOdds) external onlyAdmin() {
        rarityOdds[_rarity][_rarityOdd] = _newOdds;
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

    //TODO: THIS IS NOT TO BE USED IN FINAL DEPLOYED IMPLEMENTATION, convert to LINK VRF for TESTNET and ESPECIALLY MAINNET!!!
    uint nonce;

    function calculateWeightedOdds(uint256 randomNum, mapping(uint256 => uint256) storage rarityOdd) private view returns (uint) {
        uint256 n;

        for (n = 0; int(n) < int(maxRarityIndex); n++) {
            if (randomNum <= rarityOdd[n]) {
                return n;
            }
        }

        return n;
    }

    function softMintNFT(string memory uri, uint256 rarity) public onlyAdmin() {
        uriRarityPools[rarity].push(uri);
    }

    function burnSoftMintedNFTAtRarityIndex(uint256 rarity, uint256 index) public onlyAdmin() {
        string[] memory curRarityPool = uriRarityPools[rarity];
            for (uint i = 0; i < uriRarityPools[rarity].length; i++) {
                if (i == index) {
                    curRarityPool[i] = curRarityPool[curRarityPool.length - 1];
                    uriRarityPools[rarity] = curRarityPool;
                    uriRarityPools[rarity].pop();
                    break;
                }
            }
    }

    function compareStrings(string memory _s, string memory _s1) public pure returns (bool) {
        return (keccak256(abi.encodePacked((_s))) == keccak256(abi.encodePacked((_s1))));
    }

    function configureVRF(address _vrfAddress) public {
        vrf = RandomNumberConsumer(_vrfAddress);
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

    function getRandIndexPercentOdds(uint256 _tokenId) public view onlyAdmin() returns (uint256) {
        uint256 randRes = vrf.getRandomResultForToken(_tokenId);
        uint256 tr = tokenRarity[_tokenId];
        uint256 randIndexWithPercentOdds = calculateWeightedOdds(randRes, rarityOdds[tr]);
        return randIndexWithPercentOdds;
    }

    function getRandIndexRarity(uint256 _tokenId) public view onlyAdmin() returns (uint256) {
        uint256 rawRandRes = vrf.getRandomRawResultForToken(_tokenId);

        uint256 randRes = vrf.getRandomResultForToken(_tokenId);
        uint256 tr = tokenRarity[_tokenId];
        uint256 randIndexWithPercentOdds = calculateWeightedOdds(randRes, rarityOdds[tr]);

        uint256 randIndexInRarity = rawRandRes % (uriRarityPools[randIndexWithPercentOdds].length - 1);

        return randIndexInRarity;
    }

    function openPack(uint256 _tokenId) public {
        // Randomly 
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Viridian Pack: must be approved or owner to open");
        require(packResultDecided[_tokenId], "Viridian Pack: pack result not decided yet");

        uint256 rawRandRes = vrf.getRandomRawResultForToken(_tokenId);
        uint256 randRes = vrf.getRandomResultForToken(_tokenId);

        require(rawRandRes > 0, "Viridian Pack: VRF hasn't generated random raw result yet");
        require(randRes > 0, "Viridian Pack: VRF hasn't generated random result yet");

        uint256 tr = tokenRarity[_tokenId];

        string[10] memory newUris;

        //Need to delete the item from the rarity pool before minting happens again
        for (uint8 n = 0; n < numNFTs[tr]; n++) {
            uint256 randIndexWithPercentOdds = calculateWeightedOdds(randRes, rarityOdds[tr]);
            uint256 randIndexInRarity = rawRandRes % (uriRarityPools[randIndexWithPercentOdds].length - 1);

            string memory newURI = uriRarityPools[randIndexWithPercentOdds][randIndexInRarity];

            vNFT.mint(_msgSender(), newURI);

            newUris[n] = newURI;

            string[] memory curRarityPool = uriRarityPools[randIndexWithPercentOdds];
            for (uint i = 0; i < uriRarityPools[randIndexWithPercentOdds].length; i++) {
                string memory uri = uriRarityPools[randIndexWithPercentOdds][i];
                if (compareStrings(uri, newURI)) {
                    curRarityPool[i] = curRarityPool[curRarityPool.length - 1];
                    uriRarityPools[randIndexWithPercentOdds] = curRarityPool;
                    uriRarityPools[randIndexWithPercentOdds].pop();
                    break;
                }
            }
        }

        burn(_tokenId);

        emit Open(newUris);
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId));

        _burn(tokenId);
    }

    function awardItem(address recipient, string memory hash, string memory metadata) public returns (uint256) {
        require(hashes[hash] != 1);
        hashes[hash] = 1;
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, metadata);
        return newItemId;
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