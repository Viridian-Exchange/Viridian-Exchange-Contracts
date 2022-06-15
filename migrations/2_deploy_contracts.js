const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");
var ViridianToken = artifacts.require("ERC20TokenGasless");
var ViridianNFT = artifacts.require("ViridianNFT");
//var ViridianPack = artifacts.require("ViridianPack");
var ViridianExchange = artifacts.require("ViridianExchange");
var ViridianExchangeOffers = artifacts.require("ViridianExchangeOffers");
//var RandomNumber = artifacts.require("RandomNumberConsumer");
//var ViridianPass = artifacts.require("ViridianPass");


module.exports = async function(deployer) {
  let tokenAddr;
  let forwarderAddress = '0x9399BB24DBB5C4b782C70c2969F58716Ebbd6a3b';
  //let passForwarderAddress = '0xFD4973FeB2031D4409fB57afEE5dF2051b171104';
  let treasuryAddress = '0x341Ab3097C45588AF509db745cE0823722E5Fb19';
  let packURI = "https://api.viridianexchange.com/pack/";
  let openedURI = "https://api.viridianexchange.com/vnft/";
  let nftAddr;
  let excAddr;
  let excOffAddr;
  //let packAddr;
  //let vrfAddr;
  //let passAddr;
  const ViridianNFTDeploy = await deployProxy(ViridianNFT, [forwarderAddress, '0x12A80DAEaf8E7D646c4adfc4B107A2f1414E2002', '0x341Ab3097C45588AF509db745cE0823722E5Fb19', '0xb0897686c545045afc77cf20ec7a532e3120e0f1', "https://api.viridianexchange.com/pack/", "https://api.viridianexchange.com/vnft/", 2], { deployer, initializer: 'initialize' });
  //console.log('Deployed', ViridianNFTDeploy.address);
  // await deployer.deploy(ViridianToken, forwarderAddress).then(c => tokenAddr = c.address);
  // await deployer.deploy(ViridianNFT, forwarderAddress, treasuryAddress, packURI, openedURI).then(c => nftAddr = c.address);
  // await deployer.deploy(ViridianExchange, tokenAddr, nftAddr, forwarderAddress, treasuryAddress).then(c => excAddr = c.address);
  // await deployer.deploy(ViridianExchangeOffers, tokenAddr, nftAddr, forwarderAddress, treasuryAddress).then(c => excOffAddr = c.address);
  ////await deployer.deploy(RandomNumber, packAddr, forwarderAddress).then(c => vrfAddr = c.address);
  //await deployer.deploy(ViridianPass, 'https://d4xub33rt3s5u.cloudfront.net/v1ep.json', passForwarderAddress, treasuryAddress).then(c => passAddr = c.address);
};
