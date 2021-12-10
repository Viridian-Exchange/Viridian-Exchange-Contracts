//const Migrations = artifacts.require("ViridianToken");
const Migrations1 = artifacts.require("ViridianNFT");
const Migrations2 = artifacts.require("ViridianExchangeSimple");

module.exports = async function (deployer) {
  //await deployer.deploy(Migrations);
  await deployer.deploy(Migrations1);
  await deployer.deploy(Migrations2, '0x326C977E6efc84E512bB9C30f76E30c160eD06FB', Migrations1.address);
};
