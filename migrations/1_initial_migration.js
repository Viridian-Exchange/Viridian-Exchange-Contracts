const Migrations = artifacts.require("ViridianToken");
const Migrations1 = artifacts.require("ViridianNFT");
const Migrations2 = artifacts.require("ViridianExchange");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(Migrations1);
  deployer.deploy(Migrations2);
};
