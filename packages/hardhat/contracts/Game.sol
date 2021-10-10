pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./Accounts.sol";

import "./StakeManager.sol";

import "./Items.sol";

contract Game {
    Accounts private accounts;
    StakeManager private stakeManager;
    Items private items;

    constructor(Accounts _accounts, StakeManager _stakeManager, Items _items) {
        accounts = _accounts;
        stakeManager = _stakeManager;
        items = _items;
    }

    function newPlayer(
        address player,
        string memory playerStateURI,
        uint8 accountType,
        uint256 amount,
        uint8 stakeType
    ) external {
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
        require(
            stakeType == 0 || stakeType == 1 || stakeType == 2,
            "La Vie: Wrong stake type."
        );

        if (accountType == 1) {
            require(amount == 0, "La Vie: Can't stake with accountType 1!");
        } else if (accountType == 2) {
            require(amount == (100 ether), "La Vie: Wrong stake amount!");
            stakeManager.stake(msg.sender, amount, 60, stakeType);
        } else if (accountType == 3) {
            require(amount >= (200 ether), "La Vie: Wrong stake amount!");
            stakeManager.stake(msg.sender, amount, 120, stakeType);
        }
        createPlayerAccount(player, playerStateURI, accountType);
    }

    function deletePlayer(address player, uint256 tokenId) external {
        require(!stakeManager.isStakingBool(player), "La Vie: Unstake first!");
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

    function playerReceivesRandomItemFromCrate(
        address player,
        uint256 tokenId,
        uint8 tier
    ) external {
        require(accounts.exists(tokenId), "La Vie: token does not exist");
        require(
            msg.sender == accounts.getAccountOwner(tokenId),
            "La Vie: Account not owned"
        );
        uint256 itemId = items.getRandomItemIDFromCrate(tier);
        playerReceivesAnItem(player, tokenId, itemId);
    }

    function playerReceivesAnItem(
        address player,
        uint256 tokenId,
        uint256 itemId
    ) public {
        require(accounts.itemExists(itemId), "La Vie: item does not exist");
        require(accounts.exists(tokenId), "La Vie: token does not exist");
        require(
            msg.sender == accounts.getAccountOwner(tokenId),
            "La Vie: Account not owned"
        );
        accounts.playerReceivesItemFromGame(player, tokenId, itemId);
    }

    function unstake() external {
        stakeManager.unstake(msg.sender);
    }

    function setVestID(uint64 vestID) external {
        stakeManager.setVestID(msg.sender, vestID);
    }

    function getPlayerData()
        public
        view
        returns (
            address,
            uint256,
            uint256[] memory
        )
    {
        return accounts.GetPlayerIdAndData(msg.sender);
    }

    function getStakedAmount(address player) external view returns (uint256) {
        return stakeManager.getStakedAmount(player);
    }

    function getMaturation(address player) external view returns (uint256) {
        return stakeManager.getMaturation(player);
    }

    function isStakingBool(address player) external view returns (bool) {
        return stakeManager.isStakingBool(player);
    }

    function updatePlayerState(
        address player,
        uint256 tokenId,
        string memory newTokenURI,
        uint256 amount
    ) external {
        require(accounts.exists(tokenId), "La Vie: token does not exist");
        require(
            msg.sender == accounts.getAccountOwner(tokenId),
            "La Vie: Account not owned"
        );
        stakeManager.increaseCash(player, amount);
        accounts.setTokenUri(tokenId, newTokenURI);
    }
}
