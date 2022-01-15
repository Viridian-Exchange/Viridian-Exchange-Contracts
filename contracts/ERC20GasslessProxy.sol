// pragma solidity ^0.8.0;

// import '@openzeppelin/contracts/utils/Strings.sol';
// import '@openzeppelin/contracts/metatx/ERC2771Context.sol';
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/proxy/Proxy.sol";
// import "@opengsn/contracts/src/BaseRelayRecipient.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";


// contract ERC20GaslessProxy is Ownable, BaseRelayRecipient, ERC20 {
//     ERC20[] public tokenContracts;

//     /**
//      * @param _trustedForwarder address Address of a trusted forwarder.
//      */
//     constructor(address _trustedForwarder) {}

//     string public override versionRecipient = "2.2.0";

//     function setTrustedForwarder(address _forwarder) public onlyOwner() {
//         setTrustedForwarder(_forwarder);
//     }

//     function _msgSender() internal view override(Context, BaseRelayRecipient) returns (address sender) {
//         sender = BaseRelayRecipient._msgSender();
//     }

//     function _msgData() internal view override(Context, BaseRelayRecipient) returns (bytes memory) {
//         return BaseRelayRecipient._msgData();
//     }


// }