// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract RandomEmitter is VRFConsumerBase {

  uint public contractNumber = 0;
  address public owner;

  bytes32 internal keyHash;
  bytes32 public currentRequestId;

  event Request(bytes32 requestId);
  event RandomNumber(uint randomNumber);

  constructor(
    address _vrfCoordinator,
    address _linkToken,
    bytes32 _keyHash
  ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
    owner = msg.sender;
    keyHash = _keyHash;
  }

  /// @dev Sends a random number request to the Chainlink VRF system.
  function requestRandomNumber() external {
    currentRequestId = requestRandomness(keyHash, 0.1 ether);
    emit Request(currentRequestId);
  }

  /// @dev Called by Chainlink VRF random number provider.
  function fulfillRandomness(bytes32 requestId, uint randomness) internal override {
    require(requestId == currentRequestId, "The requestId is invalid.");

    contractNumber = (randomness % 50) + 1;

    emit RandomNumber((randomness % 50) + 1);
  }
}