// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RandomNumberConsumer is VRFConsumerBase, Ownable {
    
    mapping(address => bool) admins;

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public maxRange;
    uint256 public maxRange1;
    
    mapping(bytes32 => uint256) public requestIdResults;
    mapping(bytes32 => uint256) public requestIdRawResults;
    mapping(uint256 => bytes32) public tokenRequestIds;

    //mapping(uint256 => uint256) private rarityResult;
    
    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Polygon Mumbai
     * Chainlink VRF Coordinator address: 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255
     * LINK token address:                0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     * Key Hash: 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4
     */
    constructor(address _packAddr) VRFConsumerBase(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB  // LINK Token
        ) {
        admins[msg.sender] = true;
        admins[_packAddr] = true;
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 0.0001 * 10 ** 18; // 0.0001 LINK (Varies by network)
        maxRange = 1000;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] == true, 'Only admins can call this function');
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
    function getRandomNumber() public onlyAdmin() returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        requestIdResults[requestId] = (randomness % maxRange) + 1;
        requestIdRawResults[requestId] = randomness + 1;
    }

    function setMaxRange(uint256 _maxRange) public onlyAdmin() returns (uint256) {
      return maxRange = _maxRange;
    }

    function getRandomResultForToken(uint256 _tokenId) public view onlyAdmin() returns (uint256) {
        return requestIdResults[tokenRequestIds[_tokenId]];
    }

    function getRandomRawResultForToken(uint256 _tokenId) public view onlyAdmin() returns (uint256) {
        return requestIdRawResults[tokenRequestIds[_tokenId]];
    }

    function withdrawLink() external onlyAdmin() {} // - Implement a withdraw function to avoid locking your LINK in the contract
}