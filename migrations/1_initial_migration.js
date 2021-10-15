//const Migrations = artifacts.require("ViridianToken");
const Migrations1 = artifacts.require("ViridianNFT");
const Migrations2 = artifacts.require("ViridianPack");
const Migrations3 = artifacts.require("ViridianExchange");
const Migrations4 = artifacts.require("ViridianExchangeOffers");

module.exports = async function (deployer) {
  //await deployer.deploy(Migrations);
  await deployer.deploy(Migrations1);
  await deployer.deploy(Migrations2, Migrations1.address);
  await deployer.deploy(Migrations3, '0x6ee856ae55b6e1a249f04cd3b947141bc146273c', Migrations1.address, Migrations2.address);
  await deployer.deploy(Migrations4, '0x6ee856ae55b6e1a249f04cd3b947141bc146273c', Migrations1.address, Migrations2.address);
  //await Migrations1.setApprovalForAll(Migrations2.address, true);
};
