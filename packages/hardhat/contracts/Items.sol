pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";


//@dev will premint/new items
//@dev will hold preminted items
//@dev will safeTransfer preminted/new items

contract Items is ERC1155Supply, Ownable {
    /*struct ItemSpecs {
        uint256 minted; // the amount of items minted
        uint256 released; // the amount of items that have been trasnferred to players
    }
    mapping(uint256 => ItemSpecs) public inventory;*/

    constructor(uint256[] memory ids, uint256[] memory amounts) ERC1155('') {
        mintBatch(address(this), ids, amounts, "");
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }
}