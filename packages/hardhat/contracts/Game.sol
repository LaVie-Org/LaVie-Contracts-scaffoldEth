pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./Accounts.sol";

import "./StakeManager.sol";

contract Game {
    Accounts public accounts;
    StakeManager public stakeManager;

    constructor(Accounts _accounts, StakeManager _stakeManager) {
        accounts = _accounts;
        stakeManager = _stakeManager;
    }

    function newPlayer(
        address player,
        string memory playerStateURI,
        uint8 accountType
    ) external payable{

        //1. take stake
        //2. create account
        //3. assign items
        //1:15;30
        require(
            accounts.players(player) == 0,
            "La Vie: Player already exists."
        );
        require(
            msg.sender == player,
            "La Vie: Cannot create an account for another Address."
        );
        require(
            accountType == 1 || accountType == 2 || accountType == 3,
            "La Vie: Wrong account type."
        );

        if (accountType == 2) {
            require(msg.value >= 50 ether);
            stakeManager.stake(msg.sender, msg.value, 30);
        } else if (accountType == 3) {
            require(msg.value >= 100 ether);
            stakeManager.stake(msg.sender, msg.value, 60);
        }
        createPlayerAccount(player, playerStateURI, accountType);
    }

    function deletePlayer(address player, uint256 tokenId) external {
        require(accounts.exists(tokenId), "La Vie: token does not exist");
        require(
            msg.sender == accounts.getAccountOwner(tokenId),
            "La Vie: Cannot delete an unowned account"
        );
        accounts.deleteAccount(player, tokenId);
    }

    function createPlayerAccount(
        address player,
        string memory playerStateURI,
        uint256 accountType
    ) internal returns (uint256) {
        return accounts.createAccount(player, playerStateURI, accountType);
    }

    function playerReceivesAnItem(
        address player,
        uint256 tokenId,
        uint256 itemId
    ) external {
        require(accounts.itemExists(itemId), "La Vie: item does not exist");
        require(accounts.exists(tokenId), "La Vie: token does not exist");
        require(
            msg.sender == accounts.getAccountOwner(tokenId),
            "La Vie: Account not owned"
        );
        accounts.playerReceivesItemFromGame(player, tokenId, itemId);
    }

<<<<<<< HEAD
    function unstake(address player, uint256 tokenId) external {
        require(accounts.exists(tokenId), "La Vie: token does not exist");
        require(
            msg.sender == accounts.getAccountOwner(tokenId),
            "La Vie: Cannot unstake an unowned account"
        );
        stakeManager.unstake(player);
    }

    function setVestID(uint64 vestID) external{
        stakeManager.setVestID(msg.sender, vestID);

    }
}
=======
    function checkIfAddressIsAccount() public returns(address, uint256, uint256[] memory){
        return accounts.GetPlayerIdAndData(msg.sender);
    }
}
>>>>>>> added functions to game contract
