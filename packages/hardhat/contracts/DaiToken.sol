pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Game.sol";

contract DaiToken {
    // //MUMBAI
    // address private constant DAI_ADDRESS =
    //     0x001B3B4d0F3714Ca98ba10F6042DaEbF0B1B7b6F;

    //RINKEBY
    address private constant DAI_ADDRESS =
        0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa;

    IERC20 Dai;

    constructor() {
        Dai = IERC20(DAI_ADDRESS);
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return Dai.balanceOf(_owner);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        return Dai.transferFrom(_from, _to, _value);
    }

    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining)
    {
        return Dai.allowance(owner, spender);
    }

    // function mint(uint256 amount) public {
    //     _mint(msg.sender, amount);
    // }
}
