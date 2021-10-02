pragma solidity ^0.8.4;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./LavToken.sol";
import "./interfaces/ISuperToken.sol";
import "./interfaces/DInterestInterface.sol";
import "./interfaces/IVesting02.sol";

contract StakeManager {
    // userAddress => stakingBalance
    mapping(address => uint256) public stakingBalance;
    // userAddress => isStaking boolean
    mapping(address => bool) public isStaking;
    //track the user’s unrealized yield

    struct mphStruct {
        bool isStaking;
        uint64 maturation;
        uint64 mphID;
        uint64 vestID;
        uint256 stakedAmount;
    }

    mapping(address => mphStruct) private addressToMph;

    string public name = "StakeManager";

    ERC20 public daiToken;
    LavToken public lavToken;

    //Rinkeby addresses
    address private constant DInterestPoolAddress =
        0xB4Ffd2868E8aDa5293BBC1Bceb467AB3e53760Ac;

    address private constant IVesting02Address =
        0xab5bAA840b4C9321aa66144ffB2693E2db1166C7;
    address private constant MphAddress =
        0x59EE65726f0b886Ec924271B51A3c1e78F52d1FB;

    // ISuperToken public laVxToken;

    event Stake(mphStruct);
    event Unstake(address indexed from, uint256 amount);
    event YieldWithdraw(address indexed to, uint256 amount);

    DInterestInterface pool;
    IVesting02 vesting;
    IERC20 Mph;

    //inject the token addresses
    constructor(
        ERC20 _daiToken,
        LavToken _lavToken // ISuperToken _laVxToken
    ) {
        daiToken = _daiToken;
        lavToken = _lavToken;
        // laVxToken = _laVxToken;
        pool = DInterestInterface(DInterestPoolAddress);
        vesting = IVesting02(IVesting02Address);
        Mph = IERC20(0x59EE65726f0b886Ec924271B51A3c1e78F52d1FB);
    }

    /// Core function shells
    function stake(uint256 amount, uint256 timeInDays) external {
        require(timeInDays <= 365, "above maximum days");
        require(
            amount > 0 && daiToken.balanceOf(msg.sender) >= amount,
            "Not enough DAI tokens"
        );
        require(!(addressToMph[msg.sender].isStaking), "already staking");

        // transfer
        daiToken.transferFrom(msg.sender, address(this), amount);

        uint64 maturationTimestamp = uint64(
            block.timestamp + (timeInDays * 1 days)
        );
        require(daiToken.approve(address(pool), amount));
        uint64 depositID = pool.deposit(amount, maturationTimestamp);

        addressToMph[msg.sender].isStaking = true;
        addressToMph[msg.sender].maturation = maturationTimestamp;
        addressToMph[msg.sender].mphID = depositID;
        addressToMph[msg.sender].stakedAmount = amount;

        // lavToken.mint(msg.sender, amount);

        //start streaming Superlav to staker account balance
        startStreamLav(amount);

        emit Stake(addressToMph[msg.sender]);
    }

    function startStreamLav(uint256 amount) internal view {
        // lavBalance[msg.sender] = 0;
        //start streaming 'amount'
        console.log("STREAMING..................");
        console.log(amount);
    }

    function unstake() public {
        require(addressToMph[msg.sender].isStaking, "not currently staking");
        require(
            block.timestamp >= addressToMph[msg.sender].maturation,
            "too early to unstake"
        );
        require(addressToMph[msg.sender].vestID != 0, "vestID not set");
        require(addressToMph[msg.sender].mphID != 0, "depositID not set");

        uint64 depositID = addressToMph[msg.sender].mphID;

        uint64 vestID = addressToMph[msg.sender].vestID;
        uint256 rewards = vesting.withdraw(vestID);

        console.log(rewards);

        Mph.transferFrom(address(this), msg.sender, rewards);

        uint256 virtualTokenAmount = type(uint256).max; // withdraw all funds
        bool early = false; // withdrawing after maturation​
        uint256 amount = pool.withdraw(depositID, virtualTokenAmount, early);

        daiToken.transferFrom(address(this), msg.sender, amount);

        addressToMph[msg.sender].isStaking = false;
        addressToMph[msg.sender].maturation = 0;
        addressToMph[msg.sender].mphID = 0;
        addressToMph[msg.sender].vestID = 0;
    }

    function setVestID(address account, uint64 vestID) external {
        require(addressToMph[account].vestID == 0, "vestID already set!");
        require(
            addressToMph[account].mphID != 0,
            "No deposit for this account!"
        );
        addressToMph[account].vestID = vestID;
    }
}
