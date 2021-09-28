// deploy/00_deploy_your_contract.js

const { Interface } = require("@ethersproject/abi");
const { ethers } = require("ethers");
const { Web3Provider } = require("@ethersproject/providers");
const SuperfluidSDK = require("@superfluid-finance/js-sdk");

//const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments, ethers }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const lavToken = await deploy("LavToken", {
    from: deployer,
    // args:
    log: true,
  });

// await deploy("DaiToken", {
//     from: deployer,
//     // args:
//     log: true,
//   });

  // const sf = new SuperfluidSDK.Framework({
  //     ethers: ethers.provider,
  //     tokens: ["fDAI"],
  // });

  // await sf.initialize();

  // console.log(sf)


  const rinkebyDAIAddress=   "0x5592ec0cfb4dbc12d3ab100b257153436a1f0fea"

  const stakeManager = await deploy("StakeManager", {
    from: deployer,
    args: [rinkebyDAIAddress , lavToken.address],
    log: true,
  });


  const LavToken = await ethers.getContractAt("LavToken", lavToken.address);

  await LavToken._transferOwnership(stakeManager.address);

  /*const Accounts = await ethers.getContractAt("Accounts", accounts.address);
  await Accounts.transferOwnership(game.address);*/

  //Goerli
  // const LavxToken = await ethers.getContractAt(lavxABI, "0xCa349327df5590EC52c3b2EeF3d8cE3B307f1D6a")

  // console.log((await LavxToken.balanceOf("0x7b3813a943391465Dd62B648529c337e52FbA79b")).toString())

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
module.exports.tags = [
  "YourContract",
  "DaiToken",
  "LavToken",
  "Items",
  "Accounts",
  "Game",
  "IERC20"
];
