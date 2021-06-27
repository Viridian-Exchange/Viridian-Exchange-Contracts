const Migrations = artifacts.require("ViridianToken");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
};
