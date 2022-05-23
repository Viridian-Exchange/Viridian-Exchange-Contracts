//const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');
const Migrations = artifacts.require("ERC20TokenGasless");
const Migrations1 = artifacts.require("ViridianNFT");
const Migrations3 = artifacts.require("ViridianExchange");
const Migrations4 = artifacts.require("ViridianExchangeOffers");

module.exports = async function (deployer) {
  let forwarderAddress = '0x9399BB24DBB5C4b782C70c2969F58716Ebbd6a3b';
  //const ViridianNFTDeploy = await deployProxy(Migrations1, [42], { deployer });
  //console.log('Deployed', ViridianNFTDeploy.address);
  await deployer.deploy(Migrations, forwarderAddress);
  await deployer.deploy(Migrations1, forwarderAddress, '0x341Ab3097C45588AF509db745cE0823722E5Fb19', "https://api.viridianexchange.com/pack/", "https://api.viridianexchange.com/vnft/");
  await deployer.deploy(Migrations3, Migrations.address, Migrations1.address, forwarderAddress, '0x341Ab3097C45588AF509db745cE0823722E5Fb19');
  await deployer.deploy(Migrations4, Migrations.address, Migrations1.address, forwarderAddress, '0x341Ab3097C45588AF509db745cE0823722E5Fb19');
};
