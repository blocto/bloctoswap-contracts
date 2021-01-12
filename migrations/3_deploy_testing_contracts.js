const TetherTokenTest = artifacts.require("TetherTokenTest");
const TeleportCustodyTest = artifacts.require("TeleportCustodyTest");

module.exports = async function(deployer) {
  await deployer.deploy(TetherTokenTest);
  await deployer.deploy(TeleportCustodyTest, TetherTokenTest.address);
};
