// deploy/00_deploy_your_contract.js

const { Interface } = require("@ethersproject/abi");
const { ethers } = require("ethers");
const { Web3Provider } = require("@ethersproject/providers");
const { sort } = require("ramda");
const { sor } = require("@balancer-labs/sor");
const BigNumber = require('bignumber.js');
// const SuperfluidSDK = require("@superfluid-finance/js-sdk");

//const { ethers } = require("hardhat");

const CRPFactoryArtifact = require("./CRPFactory.json");
const WeightedPoolFactoryABI = require("./WeightedPoolFactory.json")
const OraclePoolFactoryABI = require("./OraclePoolFactory.json")
const VaultABI = require("./Vault.json")

module.exports = async ({ getNamedAccounts, deployments, ethers, sor }) => {
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

  const lavToken = await deploy("LavToken", {
    from: deployer,
    // args:
    log: true,
  });

  const daiToken = await deploy("DaiToken", {
    from: deployer,
    // args:
    log: true,
  });

  const lav = await ethers.getContractAt("LavToken", lavToken.address);
  const dai = await ethers.getContractAt("DaiToken", daiToken.address);

  const stakeManager = await deploy("StakeManager", {
    from: deployer,
    args: [daiToken.address, lavToken.address],
    log: true,
  });

  console.log(deployer)
  await lav.mint(deployer,25000)
  await dai.mint(25000)
  await lav._transferOwnership(stakeManager.address);

  const weightBig = 50000000000000000n


  // Addresses are the same on all networks

  const VAULT = "0xBA12222222228d8Ba445958a75a0704d566BF2C8";

  const WEIGHTED_POOL_FACTORY = "0x8E9aa87E45e92bad84D5F8DD1bff34Fb92637dE9";
  const ORACLE_POOL_FACTORY = "0xA5bf2ddF098bb0Ef6d120C98217dD6B141c74EE0";
  const STABLE_POOL_FACTORY = "0x791F9fD8CFa2Ea408322e172af10186b2D73baBD";

  const DELEGATE_OWNER = "0xBA1BA1ba1BA1bA1bA1Ba1BA1ba1BA1bA1ba1ba1B";


const tokens = [daiToken.address, lavToken.address];

const weights = [weightBig,weightBig];

const NAME = 'Two-token Test Pool';
const SYMBOL = '50DAI-50LaV';
const swapFeePercentage = 50000000000000000n; // 0.5%

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';  

// const factory = await ethers.getContractAt(WeightedPoolFactoryABI,
// WEIGHTED_POOL_FACTORY);

const factory = await ethers.getContractAt(OraclePoolFactoryABI,
  ORACLE_POOL_FACTORY);
  const oracleEnabled = false

const vault = await ethers.getContractAt(VaultABI, VAULT);



// ZERO_ADDRESS owner means fixed swap fees
// DELEGATE_OWNER grants permission to governance for dynamic fee management
// Any other address lets that address directly set the fees
const tx = await factory.create(NAME, SYMBOL, tokens, weights,
swapFeePercentage,oracleEnabled, ZERO_ADDRESS);
const receipt = await tx.wait();


// We need to get the new pool address out of the PoolCreated event
// (Or just grab it from Etherscan)
const events = receipt.events.filter((e) => e.event === 'PoolCreated');
const poolAddress = events[0].args.pool;

// We're going to need the PoolId later, so ask the contract for it
const pool = await ethers.getContractAt('WeightedPool', poolAddress);
const poolId = await pool.getPoolId();

// Tokens must be in the same order
// Values must be decimal-normalized! (USDT has 6 decimals)
const initialBalances = [new BigNumber('25000000000'), new BigNumber('25000000000000000000000')];

const JOIN_KIND_INIT = 0;

// Construct magic userData
const initUserData =
    ethers.utils.defaultAbiCoder.encode(['uint256', 'uint256[]'], 
                                        [JOIN_KIND_INIT, initialBalances]);
const joinPoolRequest = {
  assets: tokens,
  maxAmountsIn: initialBalances,
  userData: initUserData,
  fromInternalBalance: false
} 

// Caller is "you". joinPool takes a sender (source of initialBalances)
// And a receiver (where BPT are sent). Normally, both are the caller.
// If you have a User Balance of any of these tokens, you can set
// fromInternalBalance to true, and fund a pool with no token transfers
// (well, except for the BPT out)

// Need to approve the Vault to transfer the tokens!
// Can do through Etherscan, or programmatically
await dai.approve(VAULT, 25000000000);
await lav.approve(VAULT, new BigNumber('25000000000000000000000'));
// ... same for other tokens

// joins and exits are done on the Vault, not the pool
const tx2 = await vault.joinPool(poolId, deployer, deployer, joinPoolRequest);
// You can wait for it like this, or just print the tx hash and monitor
const receipt2 = await tx2.wait();
console.log(receipt2)



  // const CRPFactory = new ethers.ContractFactory(
  //   CRPFactoryArtifact.abi,
  //   CRPFactoryArtifact.bytecode,
  //   deployer
  // );

  //   const CRPFactory = await ethers.getContractAt(
  //     CRPFactoryArtifact.abi,
  //     CRPFactoryArtifact.bytecode,
  //     // '0x39D7de7Cf0ad8fAAc56bbb7363f49695808efAf5',
  //     await provider.getSigner()
  //   );

  //   await CRPFactory.deployed();

  //   const BFactory= "0x8f7F78080219d4066A8036ccD30D588B416a40DB"

  // console.log(CRPFactory)
  //   const CRPool = await CRPFactory.newCRP(
  //     "0x152b6b3770920be18Cdfe60C85D17C50aeC9Da39",
  //     CRPFactory.pool
  //   );

  // factory = await CRPFactory.deploy();

  // factory.deployTransaction.wait();

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
module.exports.tags = [
  "YourContract",
  "DaiToken",
  "LavToken",
  "Items",
  "Accounts",
  "Game",
];
