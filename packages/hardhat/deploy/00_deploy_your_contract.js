// deploy/00_deploy_your_contract.js


const { Interface } = require("@ethersproject/abi");
// const { ethers } = require("ethers");
const { ethers } = require("hardhat");
const { Web3Provider } = require("@ethersproject/providers");
const { formatEther, parseEther } = require("@ethersproject/units");

const DAIabi = require("../contracts/externalAbis/DAIabi.json");


//const { ethers } = require("hardhat");

const VITALIK = "0xB60C61DBb7456f024f9338c739B02Be68e3F545C";
//metamask
const TARGET = "0x7b3813a943391465Dd62B648529c337e52FbA79b";

//ETHEREUM DAI
const DAI_ADDRESS = "0x6b175474e89094c44da98b954eedeac495271d0f"
//MUMBAI DAI
// const DAI_ADDRESS = "0x001b3b4d0f3714ca98ba10f6042daebf0b1b7b6f";



let stakeManager;

module.exports = async ({ getNamedAccounts, deployments, ethers }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const items = await deploy("Items", {
    from: deployer,
    args: [
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
      [
        100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
        100, 100, 100, 100, 100, 100,
      ],
    ],
    log: true,
  });

  const accounts = await deploy("Accounts", {
    from: deployer,
    args: [items.address],
    log: true,
  });


    
  await deploy("DaiToken", {
    from: deployer,
    args:[DAI_ADDRESS],
    log: true,
  });


  // await ethers.getContractAt("DaiToken", DAI);

  // const rinkebyDAIAddress = "0x5592ec0cfb4dbc12d3ab100b257153436a1f0fea";

  stakeManager = await deploy("StakeManager", {
    from: deployer,
    args: [DAI_ADDRESS],
    log: true,
  });

  const game = await deploy("Game", {
    from: deployer,
    args: [accounts.address, stakeManager.address],
    log: true,
  });

  await deploy("TheLaVieBoard", {
    from:deployer,
    log:true,
  })

<<<<<<< HEAD
=======
  // await lavToken._transferOwnership(stakeManager.address);
  //const lav = await ethers.getContract("LavToken", deployer);
  //await lav._transferOwnership(stakeManager.address);

  //

>>>>>>> added functions to game contract
  const Accounts = await ethers.getContractAt("Accounts", accounts.address);
  const Items = await ethers.getContractAt("Items", items.address);
  const StakeManager = await ethers.getContractAt("StakeManager", stakeManager.address)

  await Accounts.setAccountManager(game.address);
  await Items.setItemManager(accounts.address, accounts.address);
  await Accounts.transferOwnership(game.address);
  await StakeManager.transferOwnership(game.address)
  await Items.transferOwnership(game.address);

  const lavToken = await deploy("LavToken", {
    from: deployer,
    // args:
    log: true,
  });


  // const LavToken = await ethers.getContractAt("LavToken", lavToken.address);

  // await LavToken._transferOwnership(stakeManager.address);

  // await lavToken._transferOwnership(stakeManager.address);
  // const lav = await ethers.getContract("LavToken", deployer);
  // await lav._transferOwnership(stakeManager.address);

  //

  // const Accounts = await ethers.getContractAt("Accounts", accounts.address);
  // const Items = await ethers.getContractAt("Items", items.address);


  // await Accounts.setAccountManager(game.address);
  // await Items.setItemManager(accounts.address, accounts.address);
  // await Accounts.transferOwnership(game.address);
  // await Items.transferOwnership(game.address);


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

async function impersonate() {
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [VITALIK],
  });

  const signer = await ethers.getSigner(VITALIK);
  const signerAddress = await signer.getAddress();

  const myDAIContract = await ethers.getContractAt("DaiToken", DAI_ADDRESS, signer);

  const DAIBal = await myDAIContract.balanceOf(signerAddress);

  console.log("");
  console.log("DAI balance: " + DAIBal.toString());

  let transferBal = parseFloat(formatEther(DAIBal)) - 0.01;

  await myDAIContract.transferFrom(
    signerAddress,
    TARGET,
    parseEther(transferBal.toString())
  );
}

module.exports.tags = [
  "TheLaVieBoard",
  "YourContract",
  "DaiToken",
  "LavToken",
  "Items",
  "Accounts",
  "Game",
  "IERC20",
];

impersonate();
