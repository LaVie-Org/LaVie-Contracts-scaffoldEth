// deploy/00_deploy_your_contract.js

const { Interface } = require("@ethersproject/abi");
const { ethers } = require("ethers");
const { Web3Provider } = require("@ethersproject/providers");
// const SuperfluidSDK = require("@superfluid-finance/js-sdk");


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
  
  //Goerli network!!
  // const ProxyAddress = "0x2ef6a2073408344F9b9B17d12959E18baA429dd0"
 
  const lavToken = await deploy("LavToken",{
    from: deployer,
    // args:
    log:true,
  })

  const daiToken = await deploy("DaiToken",{
    from: deployer,
    // args:
    log:true,
  })

  const stakeManager = await deploy("StakeManager",{
    from: deployer,
    args: [daiToken.address, lavToken.address],
    log:true
  })



  const lav = await ethers.getContractAt("LavToken", lavToken.address);
  await lav._transferOwnership(stakeManager.address);

  // const abi = [{"inputs":[{"internalType":"contract ISuperfluid","name":"host","type":"address"},{"internalType":"contract SuperTokenFactoryHelper","name":"helper","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bytes32","name":"uuid","type":"bytes32"},{"indexed":false,"internalType":"address","name":"codeAddress","type":"address"}],"name":"CodeUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"contract ISuperToken","name":"token","type":"address"}],"name":"CustomSuperTokenCreated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"contract ISuperToken","name":"token","type":"address"}],"name":"SuperTokenCreated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"contract ISuperToken","name":"tokenLogic","type":"address"}],"name":"SuperTokenLogicCreated","type":"event"},{"inputs":[{"internalType":"contract ERC20WithTokenInfo","name":"underlyingToken","type":"address"},{"internalType":"enum ISuperTokenFactory.Upgradability","name":"upgradability","type":"uint8"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"symbol","type":"string"}],"name":"createERC20Wrapper","outputs":[{"internalType":"contract ISuperToken","name":"superToken","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"contract IERC20","name":"underlyingToken","type":"address"},{"internalType":"uint8","name":"underlyingDecimals","type":"uint8"},{"internalType":"enum ISuperTokenFactory.Upgradability","name":"upgradability","type":"uint8"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"symbol","type":"string"}],"name":"createERC20Wrapper","outputs":[{"internalType":"contract ISuperToken","name":"superToken","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"contract ISuperfluid","name":"host","type":"address"}],"name":"createSuperTokenLogic","outputs":[{"internalType":"address","name":"logic","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"getCodeAddress","outputs":[{"internalType":"address","name":"codeAddress","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getHost","outputs":[{"internalType":"address","name":"host","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getSuperTokenLogic","outputs":[{"internalType":"contract ISuperToken","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"customSuperTokenProxy","type":"address"}],"name":"initializeCustomSuperToken","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"proxiableUUID","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"newAddress","type":"address"}],"name":"updateCode","outputs":[],"stateMutability":"nonpayable","type":"function"}]
  
  // const factory = await  new ethers.Contract(ProxyAddress,abi);

  //  const laVxToken = await factory.createERC20Wrapper(lav.address,0,"Super Token LaVie","LaVx")

  // console.log(await factory.functions.getHost().call())
  // console.log( await factory.estimateGas.createERC20Wrapper(lav.address,0,"Super Token LaVie","LaVx"))

  
  // const sf = new SuperfluidSDK.Framework({
  //     ethers: ethers.provider
  // });
  // await sf.initialize()

// const superTokenFactory = await sf.contracts.ISuperTokenFactory.at(
//   await sf.host.getSuperTokenFactory.call()
// );

// const laVxToken = superTokenFactory.createERC20Wrapper(lav.address,0,"Super Token LaVie","LaVx")

// console.log(laVxToken)
  // const stakeManager = await deploy('StakeManager',{
  //   from: deployer,
  //   args:[daiToken.address, lavToken.address, laVxToken.address],
  //   log:true,
  // })

  
  // await lav._transferOwnership(stakeManager.address);



  /*const Accounts = await ethers.getContractAt("Accounts", accounts.address);
  await Accounts.transferOwnership(game.address);*/

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
