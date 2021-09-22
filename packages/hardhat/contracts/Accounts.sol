pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
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
    using Counters for Counters.Counter;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    Counters.Counter private _tokenIds;
    EnumerableMap.UintToAddressMap private _accountOwner;

    constructor()  ERC721("LaVAccounts", "LaVAccounts") public {}

    receive() external payable {}

    function createAccount(address recipient, string memory userTokenURI) external onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, userTokenURI);
        _accountOwner.set(newItemId, _msgSender());
        return newItemId;
    }

    function deleteAccount(uint256 tokenId) external onlyOwner {
        //require(_exists(tokenId), "NiFTi: token does not exist");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "LaVie: can't burn account not owned");
        _burn(tokenId);
        _accountOwner.remove(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory){
        return super.tokenURI(tokenId);
    }

    function getAccountOwner(uint256 tokenId) public view returns (address) {
        return _accountOwner.get(tokenId);
    }

    function isApprovedForAll(address _owner, address _operator) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }
        // otherwise, use the default ERC721.isApprovedForAll()
        return super.isApprovedForAll(_owner, _operator);
    }

    function _burn(uint256 tokenId) internal override (ERC721, ERC721URIStorage) onlyOwner {
        super._burn(tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        super.transferFrom(from, to, tokenId);
        _accountOwner.set(tokenId, to);
    }

    function _msgSender() internal override view returns (address sender) {
        return ContextMixin.msgSender();
    }
    
}
