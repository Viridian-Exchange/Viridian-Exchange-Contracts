var ViridianToken = artifacts.require("ViridianToken");
var ViridianNFT = artifacts.require("ViridianNFT");


module.exports = function(deployer) {
  deployer.deploy(ViridianToken);
  deployer.deploy(ViridianNFT);
};