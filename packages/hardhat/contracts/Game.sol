pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./Accounts.sol";

contract Game {
    Accounts public accounts;

    constructor(Accounts _accounts){
        accounts = _accounts;
    }

    function newPlayer(address player, string memory playerStateURI, uint256 accountType) public {
        //1. take stake
        //2. create account
        //3. assign items
        //1:15;30
        require(accounts.players(player) == 0, 'La Vie: Player already exists.');
        require(msg.sender == player, "La Vie: Cannot create an account for another Address.");
        require(accountType == 1 || accountType == 2 || accountType == 3, 'La Vie: Wrong account type.');
        createPlayerAccount(player, playerStateURI, accountType);
    }

    function deletePlayer(address player, uint256 tokenId) public {
        require(accounts.exists(tokenId), "La Vie: token does not exist");
        require(msg.sender == accounts.getAccountOwner(tokenId), "La Vie: Cannot delete an unowned account");
        accounts.deleteAccount(player, tokenId);
    }


    function createPlayerAccount(address player, string memory playerStateURI, uint256 accountType) internal returns(uint) {
        return accounts.createAccount(player, playerStateURI, accountType);
    }

    function playerReceivesAnItem(address player, uint256 tokenId, uint256 itemId) public {
        require(accounts.itemExists(itemId), 'La Vie: item does not exist');
        require(accounts.exists(tokenId), "La Vie: token does not exist");
        require(msg.sender == accounts.getAccountOwner(tokenId), "La Vie: Account not owned");
        accounts.playerReceivesItemFromGame(player, tokenId, itemId);
    }
}