pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "hardhat/console.sol";
import "./Accounts.sol";

//@dev will premint/new items
//@dev will hold preminted items
//@dev will safeTransfer premintednew items
contract Items is ERC1155, Ownable, VRFConsumerBase {
    address private ITEM_MANAGER;
    address private MARKETPLACE_OPERATOR;

    mapping(uint256 => uint256) private _totalSupply;

    Accounts accountContract;

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 private randomResult;

    uint256[] private values100 = new uint256[](300);
    uint256[] private values25 = new uint256[](300);
    uint256[] private values17 = new uint256[](300);

    address public temporaryOwner = 0x7b3813a943391465Dd62B648529c337e52FbA79b;
    address public temporaryOwner2 = 0x7b3813a943391465Dd62B648529c337e52FbA79b;

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
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 // LINK Token
        )
    {
        mintBatch(address(this), ids, amounts, "0x0");
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10**18; // 0.1 LINK (Varies by network)
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

    uint256 private random100Index = 0;
    uint256 private randomom25Index = 0;
    uint256 private random17Index = 0;

    function getRandomItemIDFromCrate(uint8 tier)
        external
        onlyOwner
        returns (uint256)
    {
        //prepare random number
        if (random100Index == 150) getRandomNumber();

        //repopulate random numbers
        if (random100Index == 280) populateRandoms();

        uint256[] memory rarityWeight;
        uint256[] memory weightedRareOrNot;

        uint256 currentIndex = 0;
        uint256 randomItemNumber = 0;
        uint256 randomNumber = 0;

        uint256[] memory rareOrNot;
        rareOrNot[0] = 0;
        rareOrNot[1] = 1;

        if (tier == 1) {
            rarityWeight[0] = 99;
            rarityWeight[1] = 1;
        } else if (tier == 2) {
            rarityWeight[0] = 92;
            rarityWeight[1] = 8;
        } else if (tier == 3) {
            rarityWeight[0] = 86;
            rarityWeight[1] = 14;
        }

        uint256 i = 0;

        while (currentIndex < rareOrNot.length) {
            for (i = 0; i < rarityWeight[currentIndex]; i++)
                weightedRareOrNot[weightedRareOrNot.length] = rareOrNot[
                    currentIndex
                ];
            currentIndex++;
        }
        randomNumber = values100[random100Index];
        random100Index++;

        if (weightedRareOrNot[randomNumber] == 1) {
            // get random rare item between 18 and 25
            randomItemNumber = values25[randomom25Index];
            randomom25Index++;
        } else {
            // get random normal item between 1 and 17
            randomItemNumber = values17[random17Index];
            random17Index++;
        }

        if (random100Index == 300) random100Index = 0;

        if (random17Index == 300) random17Index = 0;

        if (randomom25Index == 300) randomom25Index = 0;

        return randomItemNumber;
    }

    function getRandomNumber() public returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        require(msg.sender == temporaryOwner, "La Vie: Not callable outside contract!");
        temporaryOwner = address(this);
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomResult = randomness;
    }

    function populateRandoms() public {
        require(randomResult!=0,"La Vie: Wait a bit!");
        require(msg.sender == temporaryOwner2, "La Vie: Not callable outside contract!");
        temporaryOwner2 = address(this);

        for (uint256 i = 0; i < 300; i++) {
            values100[i] = (uint256(
                ((keccak256(abi.encode((randomResult), i))))
            ) % 100);
        }
        //18 to 25 rare items
        for (uint256 i = 0; i < 300; i++) {
            values25[i] = ((uint256(
                ((keccak256(abi.encode((randomResult + 69), i))))
            ) % (25 - 18 + 1)) + 18);
        }
        //1 to 17 normal items
        for (uint256 i = 0; i < 300; i++) {
            values17[i] =
                (uint256(((keccak256(abi.encode((randomResult + 420), i))))) %
                    17) +
                1;
        }
    }
}
