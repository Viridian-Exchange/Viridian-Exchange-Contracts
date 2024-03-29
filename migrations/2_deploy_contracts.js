//var ViridianToken = artifacts.require("ViridianToken");
var ViridianNFT = artifacts.require("ViridianNFT");
var ViridianPack = artifacts.require("ViridianPack");
var ViridianExchange = artifacts.require("ViridianExchange");
var ViridianExchangeOffers = artifacts.require("ViridianExchangeOffers");


module.exports = async function(deployer) {
  let tokenAddr = '0x6ee856ae55b6e1a249f04cd3b947141bc146273c';
  let nftAddr;
  let excAddr;
  let excOffAddr;
  let packAddr;
  //await deployer.deploy(ViridianToken).then(c => tokenAddr = c.address);
  await deployer.deploy(ViridianNFT).then(c => nftAddr = c.address);
  await deployer.deploy(ViridianPack, nftAddr).then(c => packAddr = c.address);
  await deployer.deploy(ViridianExchange, tokenAddr, nftAddr, packAddr).then(c => excAddr = c.address);
  await deployer.deploy(ViridianExchangeOffers, tokenAddr, nftAddr, packAddr).then(c => excOffAddr = c.address);
};