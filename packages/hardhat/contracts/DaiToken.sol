pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DaiToken{

    // //MUMBAI
    // address private constant DAI_ADDRESS =
    //     0x001B3B4d0F3714Ca98ba10F6042DaEbF0B1B7b6F;

        ERC20 Dai;

    constructor(address DAI_ADDRESS) {
        Dai = ERC20(DAI_ADDRESS);
    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        return Dai.approve(_spender, _value);
    }

    function balanceOf(address _owner) public view returns(uint256 balance){
        return Dai.balanceOf(_owner);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        return Dai.transferFrom(_from, _to, _value);
    }



    // function mint(uint256 amount) public {
    //     _mint(msg.sender, amount);
    // }
}
