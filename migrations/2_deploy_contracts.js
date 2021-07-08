var ViridianToken = artifacts.require("ViridianToken");
var ViridianNFT = artifacts.require("ViridianNFT");
var ViridianExchange = artifacts.require("ViridianExchange");


module.exports = function(deployer) {
  deployer.deploy(ViridianToken);
  deployer.deploy(ViridianNFT);
  deployer.deploy(ViridianExchange);
};