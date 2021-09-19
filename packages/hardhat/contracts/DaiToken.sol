pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DaiToken is ERC20 {
    constructor() ERC20("DaiToken", "DAI") {}

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}