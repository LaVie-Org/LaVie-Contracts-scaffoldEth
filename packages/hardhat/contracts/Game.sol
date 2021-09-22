pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Accounts.sol";
import "./Items.sol";

contract Game is Ownable {
    Accounts public accounts;
    Items public items;

    constructor(Accounts _accounts, Items _items){
        accounts = _accounts;
        items = _items;
    }

    function gameCreateAccount(address player, string memory playerStateURI) public onlyOwner returns(uint) {
        return accounts.createAccount(player, playerStateURI);
    }
}