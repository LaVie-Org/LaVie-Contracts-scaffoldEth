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

    function newPlayer(address player, uint256 accountType, string memory playerStateURI) public payable {
        //1. take stake
        //2. create account
        //3. assign items
    }

    function createPlayerAccount(address player, string memory playerStateURI) internal onlyOwner returns(uint) {
        return accounts.createAccount(player, playerStateURI);
    }

    function assignItemsToPlayer(address player, uint256 accountType) internal onlyOwner {
        if(accountType == 3){
            //assuming items are pre-minted
            //initiate w/ 3 basic items and 1 rare
            //knife, brass knuckles, bat
            //rare item should be random? Init chainlink random #
            items.safeBatchTransferFrom(items, player, [1, 5, 9], [1, 1, 1], "");
        } else if (accountType == 2){
            //assuming items are pre-minted
            //initiate w/ 2 basic items
            //knife, bat
            items.safeBatchTransferFrom(items, player, [1, 9], [1, 1], "");
        } else {
            //skip
            //basic accounts, tier 1 do not get any items.
        }
    }
}