pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Items.sol";
import "hardhat/console.sol";

abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

contract Accounts is ERC721, ERC721URIStorage, ContextMixin, Ownable {
    address private ACCOUNT_MANAGER;
    address private MARKETPLACE_OPERATOR;

    using Counters for Counters.Counter;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    Counters.Counter private _tokenIds;
    EnumerableMap.UintToAddressMap private _accountOwner;

    Items public itemsContract;

    struct ItemInventory {
        uint256 amount;
    }

    struct Account {
        address owner;
        uint256 accountId;
        uint256[] items; //account nft id
        mapping(uint256 => ItemInventory) inventory;
        bool deleted;
    }

    mapping(uint256 => mapping(address => Account)) public account;
    mapping(address => uint256) public players;

    event AccountCreated(address player);
    event AccountSwapped(address newPlayer, address oldPlayer);
    event AccountDeleted(address player);
    event ItemReceived(address player, uint256 tokenId, uint256 itemId);


    constructor(Items _items) ERC721("LaVAccounts", "LaVAccounts") {

        itemsContract = _items;
        ACCOUNT_MANAGER = owner();
    }

    receive() external payable {}

    function setAccountManager(address accountManager) public onlyOwner {
        ACCOUNT_MANAGER = accountManager;
    }

    function setMarketplaceOperator(address marketplaceOperator)
        public
        onlyOwner
    {
        MARKETPLACE_OPERATOR = marketplaceOperator;
    }

    function createAccount(
        address player,
        string memory playerTokenURI,
        uint256 accountType
    ) external onlyOwner returns (uint256) {

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(player, newItemId);
        _setTokenURI(newItemId, playerTokenURI);
        _accountOwner.set(newItemId, player);
        players[player] = newItemId;
        initAccountItems(player, newItemId, accountType);
        account[newItemId][player].owner = player;
        account[newItemId][player].accountId = newItemId;
        emit AccountCreated(player);
        return newItemId;
    }

    function deleteAccount(address player, uint256 tokenId) external onlyOwner {

        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "LaVie: can't burn account not owned"
        );

        _burn(tokenId);
        deleteAccountItems(player, tokenId);
        delete account[tokenId][player];
        account[tokenId][player].deleted = true;
        delete players[player];
        _accountOwner.remove(tokenId);
        emit AccountDeleted(player);
    }


    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {

        return super.tokenURI(tokenId);
    }

    function getAccountOwner(uint256 tokenId) public view returns(address) {
        return _accountOwner.get(tokenId);
    }


    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {

        super.transferFrom(from, to, tokenId);
        changeAccountOwnership(from, tokenId, to);
        _accountOwner.set(tokenId, to);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {

        super._burn(tokenId);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return super._exists(tokenId);
    }


    function initAccountItems(
        address player,
        uint256 accountId,
        uint256 accountType
    ) private onlyOwner {
        if (accountType == 3) {

            //assuming items are pre-minted
            //initiate w/ 3 basic items and 1 rare
            //knife, brass knuckles, bat (1,5,9)
            //rare item should be random? Init chainlink random #
            uint256[] memory ids = new uint256[](3);
            uint256[] memory amounts = new uint256[](3);
            ids[0] = 1;
            ids[1] = 5;
            ids[2] = 9;
            amounts[0] = 1;
            amounts[1] = 1;
            amounts[2] = 1;
            transferItemsFromGameToAccount(player, accountId, ids, amounts);
        } else if (accountType == 2) {

            //assuming items are pre-minted
            //initiate w/ 2 basic items
            //knife, bat
            //itemsContract.safeBatchTransferFrom(address(itemsContract), player, [1, 9], [1, 1], "");
            uint256[] memory ids = new uint256[](2);
            uint256[] memory amounts = new uint256[](2);
            ids[0] = 1;
            ids[1] = 9;
            amounts[0] = 1;
            amounts[1] = 1;
            transferItemsFromGameToAccount(player, accountId, ids, amounts);
        } else {
            //skip
            //basic accounts, tier 1 do not get any items.
        }
    }

    function transferItemsFromGameToAccount(
        address player,
        uint256 accountId,
        uint256[] memory ids,
        uint256[] memory amounts
    ) private onlyOwner {
        itemsContract.transferBatchFromGame(
            address(itemsContract),
            player,
            ids,
            amounts,
            "0x0"
        );

        account[accountId][player].items = ids;
        for (uint256 i = 0; i < ids.length; ++i) {
            account[accountId][player].inventory[ids[i]].amount = amounts[i];
        }
    }


    function changeAccountOwnership(
        address oldPlayer,
        uint256 accountId,
        address newPlayer
    ) private {
        uint256[] memory itemCount = getItemAmounts(oldPlayer, accountId);
        itemsContract.transferBatchFromGame(
            oldPlayer,
            newPlayer,
            account[accountId][oldPlayer].items,
            itemCount,
            "0x0"
        );

        account[accountId][newPlayer].owner = newPlayer;
        account[accountId][newPlayer].accountId = account[accountId][oldPlayer]
            .accountId;
        account[accountId][newPlayer].items = account[accountId][oldPlayer]
            .items;
        account[accountId][newPlayer].deleted = account[accountId][oldPlayer]
            .deleted;

        uint256[] memory ids = account[accountId][newPlayer].items;
        for (uint256 i = 0; i < ids.length; ++i) {
            account[accountId][newPlayer].inventory[ids[i]].amount = account[
                accountId
            ][oldPlayer].inventory[ids[i]].amount;

        }

        delete account[accountId][oldPlayer];
        account[accountId][oldPlayer].deleted = true;
        players[newPlayer] = players[oldPlayer];
        players[oldPlayer] = 0;
        emit AccountSwapped(oldPlayer, newPlayer);
    }


    function deleteAccountItems(address player, uint256 accountId)
        private
        onlyOwner
    {
        uint256[] memory itemCount = getItemAmounts(player, accountId);
        itemsContract.burnBatch(
            player,
            account[accountId][player].items,
            itemCount
        );
    }

    function playerReceivesItemFromGame(
        address player,
        uint256 accountId,
        uint256 itemId
    ) public onlyOwner {
        itemsContract.transferFromGame(
            address(itemsContract),
            player,
            itemId,
            1,
            "0x0"
        );
        addItemToAccount(player, accountId, itemId, 1);
    }

    function playerReceivesMultItemFromGame(
        address player,
        uint256 accountId,
        uint256[] memory itemIds
    ) public onlyOwner {
        for (uint256 i = 0; i < itemIds.length; i++) {

            playerReceivesItemFromGame(player, accountId, itemIds[i]);
        }
    }


    function playerReceivesItemFromMarket(
        address fromPlayer,
        address toPlayer,
        uint256 itemId,
        uint256 amount
    ) public {
        require(
            _msgSender() == address(itemsContract),
            "La Vie: Function callable only on trade."
        );

        uint256 fromAccountId = players[fromPlayer];
        uint256 toAccountId = players[toPlayer];
        addItemToAccount(toPlayer, toAccountId, itemId, amount);
        deleteItemFromAccount(fromPlayer, fromAccountId, itemId, amount);
    }

    function playerReceivesMultItemFromMarket(
        address fromPlayer,
        address toPlayer,
        uint256[] memory itemIds,
        uint256[] memory amounts
    ) public {
        require(
            _msgSender() == address(itemsContract),
            "La Vie: Function callable only on trade."
        );
        for (uint256 i = 0; i < itemIds.length; i++) {
            playerReceivesItemFromMarket(
                fromPlayer,
                toPlayer,
                itemIds[i],
                amounts[i]
            );
        }
    }

    function addItemToAccount(
        address player,
        uint256 accountId,
        uint256 itemId,
        uint256 amount
    ) internal {
        account[accountId][player].items.push(itemId);
        account[accountId][player].inventory[itemId].amount += amount;
        emit ItemReceived(player, accountId, itemId);
    }

    function deleteItemFromAccount(
        address player,
        uint256 accountId,
        uint256 itemId,
        uint256 amount
    ) internal {
        uint256 arrLength = account[accountId][player].items.length;

        for (uint256 i = 0; i < arrLength; i++) {
            if (account[accountId][player].items[i] == itemId) {
                if (i == arrLength - 1) {
                    delete account[accountId][player].items[i];
                } else {
                    account[accountId][player].items[i] = account[accountId][
                        player
                    ].items[arrLength - 1];
                    delete account[accountId][player].items[arrLength - 1];
                }
                break;
            }
        }
        account[accountId][player].items.pop();
        account[accountId][player].inventory[itemId].amount -= amount;
    }


    function getItemAmounts(address player, uint256 accountId)
        private
        view
        returns (uint256[] memory)
    {

        uint256[] memory ids = account[accountId][player].items;
        uint256[] memory amounts = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            amounts[i] = account[accountId][player].inventory[ids[i]].amount;
        }
        return amounts;
    }


    function itemExists(uint256 itemId) public view returns (bool) {
        return itemsContract.exists(itemId);
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (
            _operator == address(MARKETPLACE_OPERATOR) ||
            _operator == address(ACCOUNT_MANAGER)
        ) {

            return true;
        }
        // otherwise, use the default ERC721.isApprovedForAll()
        return super.isApprovedForAll(_owner, _operator);
    }


    function _msgSender() internal view override returns (address sender) {

        return ContextMixin.msgSender();
    }
}
