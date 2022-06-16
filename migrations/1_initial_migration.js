const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");
const { deploy } = require("@openzeppelin/truffle-upgrades/dist/utils");
const Migrations = artifacts.require("ERC20TokenGasless");
const Migrations1 = artifacts.require("ViridianNFT");
// const Migrations3 = artifacts.require("ViridianExchange");
// const Migrations4 = artifacts.require("ViridianExchangeOffers");
const MigTest = artifacts.require("UpgradeTest");

module.exports = async function (deployer) {
  let forwarderAddress = '0x9399BB24DBB5C4b782C70c2969F58716Ebbd6a3b';
  console.log("VNFT MIG 1: " + JSON.stringify(Migrations1.contractName))
  const ViridianNFTDeploy = await deployProxy(Migrations1, [forwarderAddress, '0x12A80DAEaf8E7D646c4adfc4B107A2f1414E2002', '0x341Ab3097C45588AF509db745cE0823722E5Fb19', '0xb0897686c545045afc77cf20ec7a532e3120e0f1', "https://api.viridianexchange.com/pack/", "https://api.viridianexchange.com/vnft/", 2], { deployer });
  //await deployProxy(MigTest, [], { deployer });
  //console.log('Deployed', ViridianNFTDeploy.address);
  //await deployer.deploy(Migrations, forwarderAddress);
  //await deployer.deploy(Migrations1, forwarderAddress, '0x341Ab3097C45588AF509db745cE0823722E5Fb19', "https://api.viridianexchange.com/pack/", "https://api.viridianexchange.com/vnft/");
  //await deployer.deploy(Migrations3, Migrations.address, Migrations1.address, forwarderAddress, '0x341Ab3097C45588AF509db745cE0823722E5Fb19');
  //await deployer.deploy(Migrations4, Migrations.address, Migrations1.address, forwarderAddress, '0x341Ab3097C45588AF509db745cE0823722E5Fb19');
};
