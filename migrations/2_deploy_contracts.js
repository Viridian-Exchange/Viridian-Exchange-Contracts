var ViridianToken = artifacts.require("ViridianToken");
var ViridianNFT = artifacts.require("ViridianNFT");
var ViridianExchange = artifacts.require("ViridianExchange");


module.exports = async function(deployer) {
  let tokenAddr;
  let nftAddr;
  await deployer.deploy(ViridianToken).then(c => tokenAddr = c.address);
  await deployer.deploy(ViridianNFT).then(c => nftAddr = c.address);
  await deployer.deploy(ViridianExchange, tokenAddr, nftAddr);
};