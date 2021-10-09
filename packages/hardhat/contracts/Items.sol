pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "./Accounts.sol";

//@dev will premint/new items
//@dev will hold preminted items
//@dev will safeTransfer premintednew items
contract Items is ERC1155, Ownable {
    address private ITEM_MANAGER;
    address private MARKETPLACE_OPERATOR;

    mapping(uint256 => uint256) private _totalSupply;

    Accounts accountContract;

    modifier onlyManager() {
        require(
            _msgSender() == ITEM_MANAGER || _msgSender() == owner(),
            "Only manager can call!"
        );
        _;
    }

    constructor(uint256[] memory ids, uint256[] memory amounts)
        ERC1155(
            "https://siasky.net/EACKHO_TowvwzA0e2FiH2AE6lz9r_gsfQfQ37JhSd4JcJg/{id}.json"
        )
    {
        mintBatch(address(this), ids, amounts, "0x0");
    }

    function totalSupply(uint256 id) public view returns (uint256) {
        return _totalSupply[id];
    }

    function exists(uint256 id) public view returns (bool) {
        return totalSupply(id) > 0;
    }

    function setItemManager(address itemManager, Accounts _account)
        public
        onlyOwner
    {
        ITEM_MANAGER = itemManager;
        accountContract = _account;
    }

    function setMarketplaceOperator(address marketplaceOperator)
        public
        onlyOwner
    {
        MARKETPLACE_OPERATOR = marketplaceOperator;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner onlyManager {
        _mint(account, id, amount, data);
        _totalSupply[id] += amount;
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner onlyManager {
        _mintBatch(to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] += amounts[i];
        }
    }

    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) public onlyManager {
        super._burn(account, id, amount);
        _totalSupply[id] -= amount;
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public onlyManager {
        super._burnBatch(account, ids, amounts);
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] -= amounts[i];
        }
    }

    function transferFromGame(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyManager {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        super._safeTransferFrom(from, to, id, amount, data);
    }

    function transferBatchFromGame(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyManager {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        super._safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        require(
            accountContract.players(to) != 0,
            "La Vie: Trade can only happen between active La Vie Players."
        );
        _safeTransferFrom(from, to, id, amount, data);
        accountContract.playerReceivesItemFromMarket(from, to, id, amount);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        require(
            accountContract.players(to) != 0,
            "La Vie: Trade can only happen between active La Vie Players."
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
        accountContract.playerReceivesMultItemFromMarket(
            from,
            to,
            ids,
            amounts
        );
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
            _operator == address(ITEM_MANAGER)
        ) {
            return true;
        }
        // otherwise, use the default ERC721.isApprovedForAll()
        return super.isApprovedForAll(_owner, _operator);
    }

    function getRandomItemFromCrate(uint8 tier) external onlyOwner{
        // uint256[] memory rarityWeight;
        // uint256[] memory weightedRareOrNot;

        // uint256 currentIndex = 0;
        // uint256 randomItemNumber = 0;
        // uint256 randomNumber = 0;

        // uint256[] memory rareOrNot = [0, 1];

        // if (tier == 1) rarityWeight = [99, 1];
        // else if (tier == 2) {
        //     rarityWeight = [92, 8];
        // } else if (tier == 3) {
        //     rarityWeight = [86, 14];
        // }

        // uint i = 0;

        //   while (currentIndex < rareOrNot.length) {
        //     for (i = 0; i < rarityWeight[currentIndex]; i++)
        //       weightedRareOrNot[weightedRareOrNot.length] = rareOrNot[currentIndex];
        //     currentIndex++;
        //   }
        //   randomNumber = Math.floor(Math.random() * 100);
        //   console.log(weightedRareOrNot);
        //   console.log(weightedRareOrNot[randomNumber]);

        //   if (weightedRareOrNot[randomNumber]) {
        //     console.log("YOU GET A RARE ITEM CONGRATS!");
        //     randomItemNumber = Math.floor(Math.random() * (25 - 18 + 1) + 18);
        //   } else {
        //     console.log("normal item..");
        //     randomItemNumber = Math.floor(Math.random() * (17 - 1 + 1) + 1);
        //   }
        //   console.log("ItemID: " + randomItemNumber);
        //   return randomItemNumber;
        // }

        // itemNumber = getRandomItemFromCrate(3);
        // console.log(itemNumber);
    }
}
