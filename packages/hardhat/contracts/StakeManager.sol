pragma solidity ^0.8.4;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/DInterestInterface.sol";
import "./interfaces/CErc20.sol";
import "./interfaces/IVesting02.sol";
import "./Accounts.sol";

contract StakeManager is Ownable, IERC721Receiver {
    struct mphStruct {
        address owner;
        bool isStaking;
        uint64 maturation;
        uint64 mphID;
        uint64 vestID;
        uint256 stakedAmount;
    }

    struct cmpStruct {
        address owner;
        bool isStaking;
        uint64 maturation;
        uint256 cDAIAmount;
    }

    mapping(address => mphStruct) private addressToMph;
    mapping(address => cmpStruct) private addressToCmp;

    //0: not staking, 1: MPH staking, 2: CMP staking
    mapping(address => uint8) private addressToStakeType;

    string public name = "StakeManager";

    string public laVieImage =
        "https://siasky.net/BABQrpPo_hBwLBqVZP9LEc44f96zzi1KVXsW9GIqS2MmkQ";

    // LavToken public lavToken;

    //Rinkeby addresses
    // address private constant DInterestPoolAddress =
    //     0xB4Ffd2868E8aDa5293BBC1Bceb467AB3e53760Ac;
    // address private constant IVesting02Address =
    //     0xab5bAA840b4C9321aa66144ffB2693E2db1166C7;
    // address private constant MphAddress =
    //     0x59EE65726f0b886Ec924271B51A3c1e78F52d1FB;

    //Mainnet Ethereum
    // address private constant DInterestPoolAddress =
    //     0x11B1c87983F881B3686F8b1171628357FAA30038;
    // address private constant IVesting02Address =
    //     0x137C9A85Cde23318E3fA8d4E486cD62F46095cc8;
    // address private constant MphAddress =
    //     0x8888801aF4d980682e47f1A9036e589479e835C5;

    // RINKEBY
    address private constant DInterestPoolAddress =
        0x71482F8cD0e956051208603709639FA28cBc1F33;
    address private constant IVesting02Address =
        0xab5bAA840b4C9321aa66144ffB2693E2db1166C7;
    address private constant MphAddress =
        0xC79a56Af51Ec36738E965e88100e4570c5C77A93;
    address private constant cDAIAddress =
        0x6D7F0754FFeb405d23C51CE938289d4835bE3b14;
    address private constant DAIAddress =
        0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa;

    event Stake1(mphStruct nft);
    event Stake2(cmpStruct nft);
    event Unstake(address to, uint256 amount);
    event MyLog(string, uint256);

    DInterestInterface pool;
    IVesting02 vesting;
    IERC20 Mph;
    CErc20 cDAI;
    IERC20 daiToken;

    constructor() {
        daiToken = IERC20(DAIAddress);
        pool = DInterestInterface(DInterestPoolAddress);
        vesting = IVesting02(IVesting02Address);
        Mph = IERC20(MphAddress);
        cDAI = CErc20(cDAIAddress);
    }

    /// Core function shells
    function stake(
        address player,
        uint256 amount,
        uint256 timeInDays,
        uint8 stakeType
    ) external onlyOwner {
        uint256 allowance = daiToken.allowance(player, address(this));
        require(allowance >= amount, "check the token allowance");
        require(timeInDays <= 365, "above maximum days");
        require(
            amount > 0 && daiToken.balanceOf(player) >= amount,
            "Not enough DAI tokens"
        );

        // transfer
        daiToken.transferFrom(player, payable(address(this)), amount);
        console.log("transfered");

        if (stakeType == 1) {
            console.log("supply to 88mph called");
            supplyDAITo88MPH(player, amount, timeInDays, stakeType);
        } else if (stakeType == 2) {
            console.log("supply to CMP called");
            supplyDAIToCompound(player, amount, timeInDays, stakeType);
        }
    }

    function unstake(address player) external onlyOwner {
        require(
            addressToStakeType[player] != 0,
            "La Vie: Not currently staking!"
        );
        if (addressToStakeType[player] == 1) {
            redeemDAIFrom88mph(player);
        } else if (addressToStakeType[player] == 2) {
            redeemDAIFromCMP(player);
        }
    }

    function supplyDAITo88MPH(
        address player,
        uint256 amount,
        uint256 timeInDays,
        uint8 stakeType
    ) internal {
        require(!(addressToMph[player].isStaking), "La Vie: Already staking!");

        uint64 maturationTimestamp = uint64(
            block.timestamp + (timeInDays * 1 days)
        );
        console.log(maturationTimestamp);
        require(daiToken.approve(address(pool), amount));
        console.log("approved");
        (uint64 depositID, ) = pool.deposit(
            amount,
            maturationTimestamp
            // 0
            // laVieImage
        );

        console.log(depositID);

        console.log("mph deposit");

        addressToMph[player].owner = player;
        addressToMph[player].isStaking = true;
        addressToMph[player].maturation = maturationTimestamp;
        addressToMph[player].mphID = depositID;
        addressToMph[player].stakedAmount = amount;

        console.log(
            "Mph struct of %s: ID: %s with maturation of %s",
            player,
            addressToMph[player].mphID,
            addressToMph[player].maturation
        );
        console.log("depositID for %s : %s ", player, depositID);

        addressToStakeType[player] = stakeType;

        emit Stake1(addressToMph[msg.sender]);
    }

    function supplyDAIToCompound(
        address player,
        uint256 amount,
        uint256 timeInDays,
        uint8 stakeType
    ) public returns (uint256) {
        require(!(addressToCmp[player].isStaking), "La Vie: Already staking!");

        uint64 maturationTimestamp = uint64(
            block.timestamp + (timeInDays * 1 days)
        );

        // Amount of current exchange rate from cToken to underlying
        uint256 exchangeRateMantissa = cDAI.exchangeRateCurrent();
        emit MyLog("Exchange Rate (scaled up): ", exchangeRateMantissa);

        console.log("Exchange Rate (scaled up): %s", exchangeRateMantissa);

        //Amount added to your supply balance this block
        uint256 supplyRateMantissa = cDAI.supplyRatePerBlock();
        emit MyLog("Supply Rate (scaled up): ", supplyRateMantissa);

        console.log("Supply Rate (scaled up): %s", supplyRateMantissa);

        //Approve transfer on the DAI contract
        daiToken.approve(cDAIAddress, amount);

        uint256 myBefore = mycDAIbalance();

        // Mint cTokens
        uint256 mintResult = cDAI.mint(amount);

        uint256 myAfter = mycDAIbalance();

        addressToCmp[player].owner = player;
        addressToCmp[player].isStaking = true;
        addressToCmp[player].maturation = maturationTimestamp;
        addressToCmp[player].cDAIAmount = myAfter - myBefore;

        addressToStakeType[player] = stakeType;

        emit Stake2(addressToCmp[player]);

        return mintResult;
    }

    function redeemDAIFrom88mph(address player) internal {
        require(
            addressToMph[player].isStaking,
            "La Vie: Not currently staking!"
        );
        require(
            block.timestamp >= addressToMph[player].maturation,
            "too early to unstake"
        );
        require(
            addressToMph[player].owner == player,
            "you dont own this stake!"
        );
        require(addressToMph[player].vestID != 0, "vestID not set");
        require(addressToMph[player].mphID != 0, "depositID not set");

        uint64 depositID = addressToMph[player].mphID;
        console.log("depositID: %s", depositID);

        uint64 vestID = addressToMph[player].vestID;
        console.log("vestOD: %s", vestID);
        uint256 rewards = vesting.withdraw(vestID);

        console.log(rewards);

        Mph.transfer(player, rewards);

        uint256 virtualTokenAmount = type(uint256).max; // withdraw all funds
        bool early = false; // withdrawing after maturation​
        uint256 amount = pool.withdraw(depositID, virtualTokenAmount, early);

        daiToken.transfer(player, amount);

        addressToMph[player].owner = address(0);
        addressToMph[player].isStaking = false;
        addressToMph[player].maturation = 0;
        addressToMph[player].mphID = 0;
        addressToMph[player].vestID = 0;

        addressToStakeType[player] = 0;

        emit Unstake(player, amount);
    }

    function redeemDAIFromCMP(address player) internal {
        require(
            addressToCmp[player].isStaking,
            "La Vie: Not currently staking!"
        );
        require(
            block.timestamp >= addressToCmp[player].maturation,
            "too early to unstake"
        );
        require(
            addressToCmp[player].owner == player,
            "you dont own this stake!"
        );

        uint256 redeemResult;

        uint256 myDaiBefore = daiToken.balanceOf(address(this));

        uint256 cDAIamount = addressToCmp[player].cDAIAmount;

        redeemResult = cDAI.redeem(cDAIamount);

        uint256 myDaiAfter = daiToken.balanceOf(address(this));

        emit MyLog("If this is not 0, there was an error", redeemResult);
        require(redeemResult == 0, "redeemResult error");

        console.log("redeemResult: %s", redeemResult);

        uint256 difference = myDaiAfter - myDaiBefore;

        daiToken.transfer(player, difference);

        addressToCmp[player].owner = address(0);
        addressToCmp[player].isStaking = false;
        addressToCmp[player].maturation = 0;
        addressToCmp[player].cDAIAmount = 0;

        addressToStakeType[player] = 0;

        emit Unstake(player, addressToCmp[player].cDAIAmount);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setVestID(address player, uint64 vestID) external onlyOwner {
        require(
            addressToMph[player].owner == player,
            "La Vie: You dont own this stake!"
        );
        require(
            addressToMph[player].vestID == 0,
            "La Vie: vestID already set!"
        );
        require(
            addressToMph[player].mphID != 0,
            "La Vie: No deposit for this account!"
        );
        addressToMph[player].vestID = vestID;
    }

    function getStakedAmount(address player) external view returns (uint256) {
        require(
            addressToStakeType[player] != 0,
            "La Vie: Not currently staking!"
        );
        if (addressToStakeType[player] == 1) {
            return addressToMph[player].stakedAmount;
        } else if (addressToStakeType[player] == 2) {
            return addressToCmp[player].cDAIAmount;
        }
        return 0;
    }

    function getMaturation(address player) external view returns (uint64) {
        return addressToMph[player].maturation;
    }

    function isStakingBool(address player) external view returns (bool) {
        require(
            addressToStakeType[player] != 0,
            "La Vie: Not currently staking!"
        );
        if (addressToStakeType[player] == 1) {
            return addressToMph[player].isStaking;
        } else if (addressToStakeType[player] == 2) {
            return addressToCmp[player].isStaking;
        }
        return false;
    }

    function mycDAIbalance() public view returns (uint256) {
        return cDAI.balanceOf(address(this));
    }

    receive() external payable {}
}
