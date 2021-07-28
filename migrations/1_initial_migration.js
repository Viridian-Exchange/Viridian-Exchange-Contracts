const Migrations = artifacts.require("ViridianTokenOldImpl");
const Migrations1 = artifacts.require("ViridianNFT");
const Migrations2 = artifacts.require("ViridianExchange");

module.exports = async function (deployer) {
  await deployer.deploy(Migrations);
  await deployer.deploy(Migrations1);
  await deployer.deploy(Migrations2, Migrations.address, Migrations1.address);
};
