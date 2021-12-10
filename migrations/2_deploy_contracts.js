var ViridianNFT = artifacts.require("ViridianNFT");
var ViridianExchange = artifacts.require("ViridianExchangeSimple");


module.exports = async function(deployer) {
  let tokenAddr = '0x326C977E6efc84E512bB9C30f76E30c160eD06FB';
  let nftAddr;
  let excAddr;
  //await deployer.deploy(ViridianToken).then(c => tokenAddr = c.address);
  await deployer.deploy(ViridianNFT).then(c => nftAddr = c.address);
  await deployer.deploy(ViridianExchange, tokenAddr, nftAddr).then(c => excAddr = c.address);
};