var ViridianToken = artifacts.require("ViridianToken");
var ViridianNFT = artifacts.require("ViridianNFT");
var ViridianPack = artifacts.require("ViridianPack");
var ViridianExchange = artifacts.require("ViridianExchange");
var ViridianExchangeOffers = artifacts.require("ViridianExchangeOffers");
var RandomNumber = artifacts.require("RandomNumberConsumer");
var ViridianPass = artifacts.require("ViridianPass");


module.exports = async function(deployer) {
  let tokenAddr = '0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1';
  let forwarderAddress = '0x9399BB24DBB5C4b782C70c2969F58716Ebbd6a3b';
  let passForwarderAddress = '0xFD4973FeB2031D4409fB57afEE5dF2051b171104';
  let nftAddr;
  let excAddr;
  let excOffAddr;
  let packAddr;
  let vrfAddr;
  let passAddr;
  //await deployer.deploy(ViridianToken).then(c => tokenAddr = c.address);
  await deployer.deploy(ViridianNFT, forwarderAddress).then(c => nftAddr = c.address);
  await deployer.deploy(ViridianPack, nftAddr, forwarderAddress).then(c => packAddr = c.address);
  await deployer.deploy(ViridianExchange, tokenAddr, nftAddr, packAddr, forwarderAddress).then(c => excAddr = c.address);
  await deployer.deploy(ViridianExchangeOffers, tokenAddr, nftAddr, packAddr, forwarderAddress).then(c => excOffAddr = c.address);
  await deployer.deploy(RandomNumber, packAddr, forwarderAddress).then(c => vrfAddr = c.address);
  await deployer.deploy(ViridianPass, 'https://d4xub33rt3s5u.cloudfront.net/v1ep.json', passForwarderAddress).then(c => passAddr = c.address);
};