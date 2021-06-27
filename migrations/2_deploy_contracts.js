var ViridianToken = artifacts.require("ViridianToken");

module.exports = function(deployer) {
  deployer.deploy(ViridianToken);
};