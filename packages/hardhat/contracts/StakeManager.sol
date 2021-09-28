pragma solidity ^0.8.4;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./DaiToken.sol";
import "./LavToken.sol";
import "./interfaces/ISuperToken.sol";

contract StakeManager {
    // userAddress => stakingBalance
    mapping(address => uint256) public stakingBalance;
    // userAddress => isStaking boolean
    mapping(address => bool) public isStaking;
    //track the user’s unrealized yield
    // userAddress => timeStamp
    mapping(address => uint256) public startTime;
    // userAddress => lavBalance
    mapping(address => uint256) public lavBalance;

    string public name = "StakeManager";

    DaiToken public daiToken;
    LavToken public lavToken;
    // ISuperToken public laVxToken;

    event Stake(address indexed from, uint256 amount);
    event Unstake(address indexed from, uint256 amount);
    event YieldWithdraw(address indexed to, uint256 amount);

    //inject the token addresses
    constructor(
        DaiToken _daiToken,
        LavToken _lavToken
        // ISuperToken _laVxToken
    ) {
        daiToken = _daiToken;
        lavToken = _lavToken;
        // laVxToken = _laVxToken;
    }

    /// Core function shells
    function stake(uint256 amount) external {
        require(
            amount > 0 && daiToken.balanceOf(msg.sender) >= amount,
            "Not enough DAI tokens"
        );
        require(!isStaking[msg.sender], "already staking");
        //transfer
        daiToken.transferFrom(msg.sender, address(this), amount);
        stakingBalance[msg.sender] += amount;

        lavToken.mint(msg.sender, amount);

        // lavToken.increaseAllowance(address(lavToken), amount);

        // laVxToken.upgrade(amount);

        //calculate earned lav
        // lavBalance[msg.sender] += amount;

        //start streaming Superlav to staker account balance
        startStreamLav(amount * 2);

        isStaking[msg.sender] = true;
        emit Stake(msg.sender, amount);
    }

    function startStreamLav(uint256 amount) internal view {
        if (lavBalance[msg.sender] != 0) {
            // lavBalance[msg.sender] = 0;
            //start streaming 'amount'
            console.log("STREAMING..................");
            console.log(amount);
        }
    }

    function unstake() public {
        isStaking[msg.sender] = false;
        lavBalance[msg.sender] = 0;
        // require(
        //     isStaking[msg.sender] =
        //         true &&
        //         stakingBalance[msg.sender] >= amount,
        //     "Nothing to unstake"
        // );
        // uint256 yieldTransfer = calculateYieldTotal(msg.sender);
        // startTime[msg.sender] = block.timestamp;
        // uint256 balanceTransfer = amount;
        // amount = 0;
        // stakingBalance[msg.sender] -= balanceTransfer;
        // daiToken.transfer(msg.sender, balanceTransfer);
        // lavBalance[msg.sender] += yieldTransfer;
        // if (stakingBalance[msg.sender] == 0) {
        //     isStaking[msg.sender] = false;
        // }
        // emit Unstake(msg.sender, amount);
    }

    function withdrawYield() public {
        uint256 toTransfer = calculateYieldTotal(msg.sender);

        require(
            toTransfer > 0 || lavBalance[msg.sender] > 0,
            "Nothing to withdraw"
        );

        if (lavBalance[msg.sender] != 0) {
            uint256 oldBalance = lavBalance[msg.sender];
            lavBalance[msg.sender] = 0;
            toTransfer += oldBalance;
        }

        startTime[msg.sender] = block.timestamp;
        lavToken.mint(msg.sender, toTransfer);
        emit YieldWithdraw(msg.sender, toTransfer);
    }

    function calculateYieldTime(address user) public view returns (uint256) {
        uint256 end = block.timestamp;
        uint256 totalTime = end - startTime[user];
        return totalTime;
    }

    function calculateYieldTotal(address user) public view returns (uint256) {
        uint256 time = calculateYieldTime(user) * 10**18;
        uint256 rate = 86400;
        uint256 timeRate = time / rate;
        uint256 rawYield = (stakingBalance[user] * timeRate) / 10**18;
        return rawYield;
    }
}
