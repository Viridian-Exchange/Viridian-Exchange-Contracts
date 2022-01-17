//const Migrations = artifacts.require("ViridianToken");
const Migrations1 = artifacts.require("ViridianNFT");
const Migrations2 = artifacts.require("ViridianPack");
const Migrations3 = artifacts.require("ViridianExchange");
const Migrations4 = artifacts.require("ViridianExchangeOffers");
const Migrations5 = artifacts.require("RandomNumberConsumer");

module.exports = async function (deployer) {
  let forwarderAddress = '0x9399BB24DBB5C4b782C70c2969F58716Ebbd6a3b';
  //await deployer.deploy(Migrations);
  await deployer.deploy(Migrations1, forwarderAddress);
  await deployer.deploy(Migrations2, Migrations1.address, forwarderAddress);
  // Currency address is Polygon Mumbai contract
  await deployer.deploy(Migrations3, '0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1', Migrations1.address, Migrations2.address, forwarderAddress);
  await deployer.deploy(Migrations4, '0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1', Migrations1.address, Migrations2.address, forwarderAddress);
  await deployer.deploy(Migrations5, Migrations2.address, forwarderAddress);
};
