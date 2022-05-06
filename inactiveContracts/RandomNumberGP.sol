// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

contract RandomNumberConsumerGenesis is VRFConsumerBase, Ownable, BaseRelayRecipient {

    mapping(address => bool) admins;

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public maxRange;

    mapping(bytes32 => uint256) public requestTokenIds;
    mapping(bytes32 => uint256[3]) public requestIdResults;
    mapping(uint256 => bytes32) public tokenRequestIds;

    //mapping(uint256 => uint256) private rarityResult;

    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Polygon Mainnet
     * Chainlink VRF Coordinator address: 0x3d2341ADb2D31f1c5530cDC622016af293177AE0
     * LINK token address:                0xb0897686c545045aFc77CF20eC7A532E3120E0F1
     * Key Hash: 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da
     */
    constructor(address _packAddr, address _forwarderAddress, uint256 _maxRange) VRFConsumerBase(
            0x3d2341ADb2D31f1c5530cDC622016af293177AE0, // VRF Coordinator
            0xb0897686c545045aFc77CF20eC7A532E3120E0F1  // LINK Token
    ) {
        _setTrustedForwarder(_forwarderAddress);
        admins[_msgSender()] = true;
        admins[_packAddr] = true;
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
        fee = 0.0001 * 10 ** 18; // 0.0001 LINK (Varies by network)
        maxRange = _maxRange;
    }

    event RandomnessFulfilled(uint256 tokenId);

    string public override versionRecipient = "2.2.0";

    function setTrustedForwarder(address _forwarder) public onlyOwner() {
        _setTrustedForwarder(_forwarder);
    }

    function _msgSender() internal view override(Context, BaseRelayRecipient) returns (address) {
        return BaseRelayRecipient._msgSender();
    }

    function _msgData() internal view override(Context, BaseRelayRecipient) returns (bytes memory) {
        return BaseRelayRecipient._msgData();
    }

    modifier onlyAdmin() {
        require(admins[_msgSender()] == true, 'Only admins can call this function');
            _;
    }

    function addAdmin(address _newAdmin) external onlyOwner() {
        admins[_newAdmin] = true;
    }

    function removeAdmin(address _newAdmin) external onlyOwner() {
        admins[_newAdmin] = false;
    }

    /**
     * Requests randomness
     */
    function getRandomNumber(uint256 _tokenId) public onlyAdmin() returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        bytes32 _requestId = requestRandomness(keyHash, fee);
        require(tokenRequestIds[_tokenId] != _requestId, "Request Id number for token already locked in");
        tokenRequestIds[_tokenId] = _requestId;
        requestTokenIds[_requestId] = _tokenId;
        return _requestId;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        //requestIdResults[requestId] = (randomness % maxRange) + 1;

        // Do this if there are multiple random results
        for (uint i = 0; i < 3; i++) {
            requestIdResults[requestId][i] = (randomness % (maxRange - i)) + 1;
        }

        //requestIdRawResults[requestId] = randomness + 1;

        emit RandomnessFulfilled(requestTokenIds[requestId]);
    }

    function setMaxRange(uint256 _maxRange) public onlyAdmin() returns (uint256) {
        return maxRange = _maxRange;
    }

    function getRandomResultForToken(uint256 _tokenId) public view onlyAdmin() returns (uint256[3] memory) {
        return requestIdResults[tokenRequestIds[_tokenId]];
    }

    // function getRandomRawResultForToken(uint256 _tokenId) public view onlyAdmin() returns (uint256) {
    //     return requestIdRawResults[tokenRequestIds[_tokenId]];
    // }

    function withdrawLink() external onlyAdmin() {} // - Implement a withdraw function to avoid locking your LINK in the contract
}