// deploy/00_deploy_your_contract.js

// const { ethers } = require("ethers");

//const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments, ethers }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  await deploy("YourContract", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    //args: [ "Hello", ethers.utils.parseEther("1.5") ],
    log: true,
  });

  const lavToken = await deploy("LavToken",{
    from: deployer,
    // args:,
    log:true,
  })

  const daiToken = await deploy("DaiToken",{
    from: deployer,
    // args:
    log:true,
  })

  const stakeManager = await deploy('StakeManager',{
    from: deployer,
    args:[daiToken.address, lavToken.address],
    log:true,
  })

  const items = await deploy('Items',{
    from: deployer,
    args:[
      [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20], 
      [100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100], 
    ],
    log:true,
  })

  const accounts = await deploy('Accounts',{
    from: deployer,
    args:[items.address],
    log:true,
  })

  const game = await deploy('Game',{
    from: deployer,
    args:[accounts.address],
    log:true,
  })

  /*const Accounts = await ethers.getContractAt("Accounts", accounts.address);
  await Accounts.transferOwnership(game.address);*/
  // await lavToken._transferOwnership(stakeManager.address);
  const lav = await ethers.getContract("LavToken", deployer);
  await lav._transferOwnership(stakeManager.address);

  //

  const Accounts = await ethers.getContractAt("Accounts", accounts.address);
  const Items = await ethers.getContractAt("Items", items.address);


  await Accounts.setAccountManager(game.address);
  await Items.setItemManager(accounts.address, accounts.address);
  await Accounts.transferOwnership(game.address);
  await Items.transferOwnership(game.address);


  /*
    // Getting a previously deployed contract
    const YourContract = await ethers.getContract("YourContract", deployer);
    await YourContract.setPurpose("Hello");
  
    To take ownership of yourContract using the ownable library uncomment next line and add the 
    address you want to be the owner. 
    // yourContract.transferOwnership(YOUR_ADDRESS_HERE);

    //const yourContract = await ethers.getContractAt('YourContract', "0xaAC799eC2d00C013f1F11c37E654e59B0429DF6A") //<-- if you want to instantiate a version of a contract at a specific address!
  */

  /*
  //If you want to send value to an address from the deployer
  const deployerWallet = ethers.provider.getSigner()
  await deployerWallet.sendTransaction({
    to: "0x34aA3F359A9D614239015126635CE7732c18fDF3",
    value: ethers.utils.parseEther("0.001")
  })
  */

  /*
  //If you want to send some ETH to a contract on deploy (make your constructor payable!)
  const yourContract = await deploy("YourContract", [], {
  value: ethers.utils.parseEther("0.05")
  });
  */

  /*
  //If you want to link a library into your contract:
  // reference: https://github.com/austintgriffith/scaffold-eth/blob/using-libraries-example/packages/hardhat/scripts/deploy.js#L19
  const yourContract = await deploy("YourContract", [], {}, {
   LibraryName: **LibraryAddress**
  });
  */
};
module.exports.tags = ["YourContract","DaiToken","LavToken", "Items", "Accounts", "Game"];
