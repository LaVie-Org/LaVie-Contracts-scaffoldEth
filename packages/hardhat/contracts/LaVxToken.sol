pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./StakeManager.sol";

contract LaVxToken {
    //RINKEBY
    address private constant laVxAddress =
        0x71b4f145617410eE50DC26d224D202e9278D71f1;

    ERC20 private laVxToken;

    constructor() {
        laVxToken = ERC20(laVxAddress);
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        return laVxToken.approve(_spender, _value);
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return laVxToken.balanceOf(_owner);
    }

    
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining)
    {
        return laVxToken.allowance(owner, spender);
    }
}
