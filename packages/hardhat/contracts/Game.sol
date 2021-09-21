pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./Accounts.sol";

contract Game {
    Accounts public accounts;

    constructor(Accounts _accounts){
        accounts = _accounts;
    }

    function gameCreateAccount(address player, string memory playerStateURI) public returns(uint){
        return accounts.createAccount(player, playerStateURI);
    }
}