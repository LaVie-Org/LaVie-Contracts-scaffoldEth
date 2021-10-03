pragma solidity ^0.8.4;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISuperToken.sol";
import "./interfaces/DInterestInterface.sol";
import "./interfaces/IVesting02.sol";
import "./Accounts.sol";

contract StakeManager is Ownable {
    // userAddress => stakingBalance
    mapping(address => uint256) public stakingBalance;
    // userAddress => isStaking boolean
    mapping(address => bool) public isStaking;
    //track the user’s unrealized yield

    struct mphStruct {
        address owner;
        bool isStaking;
        uint64 maturation;
        uint64 mphID;
        uint64 vestID;
        uint256 stakedAmount;
    }

    mapping(address => mphStruct) private addressToMph;

    string public name = "StakeManager";

    string public laVieImage =
        "https://siasky.net/BABQrpPo_hBwLBqVZP9LEc44f96zzi1KVXsW9GIqS2MmkQ";

    ERC20 public daiToken;
    // LavToken public lavToken;

    //Rinkeby addresses
    address private constant DInterestPoolAddress =
        0xB4Ffd2868E8aDa5293BBC1Bceb467AB3e53760Ac;

    address private constant IVesting02Address =
        0xab5bAA840b4C9321aa66144ffB2693E2db1166C7;
    address private constant MphAddress =
        0x59EE65726f0b886Ec924271B51A3c1e78F52d1FB;

    // ISuperToken public laVxToken;

    event Stake(mphStruct nft);
    event Unstake(address to, uint256 amount);

    DInterestInterface pool;
    IVesting02 vesting;
    IERC20 Mph;

    //inject the token addresses
    constructor(ERC20 _daiToken) {
        daiToken = _daiToken;
        // lavToken = _lavToken;
        // laVxToken = _laVxToken;
        pool = DInterestInterface(DInterestPoolAddress);
        vesting = IVesting02(IVesting02Address);
        Mph = IERC20(0x59EE65726f0b886Ec924271B51A3c1e78F52d1FB);
    }

    /// Core function shells
    function stake(
        address player,
        uint256 amount,
        uint256 timeInDays
    ) external onlyOwner {
        require(timeInDays <= 365, "above maximum days");
        require(
            amount > 0 && daiToken.balanceOf(player) >= amount,
            "Not enough DAI tokens"
        );
        require(!(addressToMph[player].isStaking), "already staking");

        // transfer
        daiToken.transferFrom(player, payable(address(this)), amount);

        uint64 maturationTimestamp = uint64(
            block.timestamp + (timeInDays * 1 days)
        );
        require(daiToken.approve(address(pool), amount));
        (uint64 depositID, ) = pool.deposit(
            amount,
            maturationTimestamp,
            0,
            laVieImage
        );

        addressToMph[player].owner = player;
        addressToMph[player].isStaking = true;
        addressToMph[player].maturation = maturationTimestamp;
        addressToMph[player].mphID = depositID;
        addressToMph[player].stakedAmount = amount;

        emit Stake(addressToMph[msg.sender]);
    }

    function unstake(address player) external onlyOwner {
        require(addressToMph[player].isStaking, "not currently staking");
        require(
            block.timestamp >= addressToMph[player].maturation,
            "too early to unstake"
        );
        require(addressToMph[player].vestID != 0, "vestID not set");
        require(addressToMph[player].mphID != 0, "depositID not set");

        uint64 depositID = addressToMph[player].mphID;

        uint64 vestID = addressToMph[player].vestID;
        uint256 rewards = vesting.withdraw(vestID);

        console.log(rewards);

        Mph.transferFrom(address(this), payable(player), rewards);

        uint256 virtualTokenAmount = type(uint256).max; // withdraw all funds
        bool early = false; // withdrawing after maturation​
        uint256 amount = pool.withdraw(depositID, virtualTokenAmount, early);

        daiToken.transferFrom(address(this), payable(player), amount);

        addressToMph[player].owner = address(0);
        addressToMph[player].isStaking = false;
        addressToMph[player].maturation = 0;
        addressToMph[player].mphID = 0;
        addressToMph[player].vestID = 0;

        emit Unstake(player, amount);
    }

    function setVestID(address account, uint64 vestID) external onlyOwner{
        require(addressToMph[account].owner == account,"You dont own this stake!");
        require(addressToMph[account].vestID == 0, "vestID already set!");
        require(
            addressToMph[account].mphID != 0,
            "No deposit for this account!"
        );
        addressToMph[account].vestID = vestID;
    }
}
