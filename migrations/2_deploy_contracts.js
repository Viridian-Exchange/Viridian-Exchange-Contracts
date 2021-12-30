var ViridianToken = artifacts.require("ViridianToken");
var ViridianNFT = artifacts.require("ViridianNFT");
var ViridianPack = artifacts.require("ViridianPack");
var ViridianExchange = artifacts.require("ViridianExchange");
var ViridianExchangeOffers = artifacts.require("ViridianExchangeOffers");
var RandomNumber = artifacts.require("RandomNumberConsumer");


module.exports = async function(deployer) {
  let tokenAddr = '0x326C977E6efc84E512bB9C30f76E30c160eD06FB';
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