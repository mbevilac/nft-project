const NToken = artifacts.require("Nifty");



module.exports = async (deployer) => {

  await deployer.deploy(NToken, "CryptoMonsters", "K69M", 5, 1000000000000000000n);
  token = await NToken.deployed();

  await token.mint("monster1", {value: 1e18});
  await token.mint("monster2", {value: 1e18});
  await token.mint("monster3", {value: 1e18});
  await token.mint("monster4", {value: 1.02*1e18});
  await token.mint("monster5", {value: 1e18});
  
  
};