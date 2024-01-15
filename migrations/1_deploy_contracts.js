const DragonCoin = artifacts.require("DragonCoin");

module.exports = async function(deployer){

  await deployer.deploy(DragonCoin,"Token Name","LT",10000000,"0x9e10471Ff7daAD77dF0F7967077B8854157343Da");
  const DragonCoinContract = await DragonCoin.deployed();

  console.log('\n*************************************************************************\n')
  console.log(`Dragon Coin Contract Address: ${DragonCoinContract.address}`)
  console.log('\n*************************************************************************\n')

}





