var ViridianToken = artifacts.require("ViridianToken");
var ViridianNFT = artifacts.require("ViridianNFT");
var ViridianPack = artifacts.require("ViridianPack");
var ViridianExchange = artifacts.require("ViridianExchange");
var ViridianExchangeOffers = artifacts.require("ViridianExchangeOffers");
var RandomNumber = artifacts.require("RandomNumberConsumer");


module.exports = async function(deployer) {
  let tokenAddr = '0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1';
  let nftAddr;
  let excAddr;
  let excOffAddr;
  let packAddr;
  let vrfAddr;
  //await deployer.deploy(ViridianToken).then(c => tokenAddr = c.address);
  await deployer.deploy(ViridianNFT).then(c => nftAddr = c.address);
  await deployer.deploy(ViridianPack, nftAddr).then(c => packAddr = c.address);
  await deployer.deploy(ViridianExchange, tokenAddr, nftAddr, packAddr).then(c => excAddr = c.address);
  await deployer.deploy(ViridianExchangeOffers, tokenAddr, nftAddr, packAddr).then(c => excOffAddr = c.address);
  await deployer.deploy(RandomNumber, packAddr).then(c => vrfAddr = c.address);
};