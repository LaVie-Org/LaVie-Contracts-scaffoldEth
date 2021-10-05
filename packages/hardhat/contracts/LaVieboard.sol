// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Base64} from "./libraries/Base64.sol";

import "./LavToken.sol";

contract TheLaVieBoard is ERC721URIStorage {
    uint256 currentPrice = 0;

    string storedFirstLine = "";
    string storedSecondLine = "";
    string storedThirdLine = "";

     address public owner;
     address private constant laVxAddress = 0x5Dda1E95142f31F8F8ff926724BB2E3A040cAAf8;

    ERC20 private LaVxToken;

    event LaVieBoardUpdated(
        string first,
        string second,
        string third,
        uint256 price,
        address indexed by
    );

    constructor() ERC721("LaVie Board", "LAVIEBOARD") {
        owner = msg.sender;
        _safeMint(msg.sender, 1);
        LaVxToken = ERC20(laVxAddress);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string
            memory openingSvg = "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 550 250'><style>.base { fill: white; font-family: sans-serif; font-size: 22px; }</style><rect width='100%' height='100%' fill='black' />";
        string memory firstOpeningLine = "<text x='50%' y=";
        string
            memory secondOpeningLine = " class='base' dominant-baseline='middle' text-anchor='middle'>";
        string
            memory openingJson = '{"name": "The LaVie Board", "description": "Fully on chain billboard. This NFT displays the latest text stored in The LaVie Board (3 lines of 50 bytes each) and allows its owner to control the contract balance.", "image": "data:image/svg+xml;base64,';

        string memory firstLineSvg = "";
        string memory secondLineSvg = "";
        string memory thirdLineSvg = "";

        if (bytes(storedFirstLine).length != 0) {
            firstLineSvg = string(
                abi.encodePacked(
                    firstOpeningLine,
                    "'35%'",
                    secondOpeningLine,
                    storedFirstLine,
                    "</text>"
                )
            );
        }

        if (bytes(storedSecondLine).length != 0) {
            secondLineSvg = string(
                abi.encodePacked(
                    firstOpeningLine,
                    "'50%'",
                    secondOpeningLine,
                    storedSecondLine,
                    "</text>"
                )
            );
        }

        if (bytes(storedThirdLine).length != 0) {
            thirdLineSvg = string(
                abi.encodePacked(
                    firstOpeningLine,
                    "'65%'",
                    secondOpeningLine,
                    storedThirdLine,
                    "</text>"
                )
            );
        }

        string memory finalSvg = string(
            abi.encodePacked(
                openingSvg,
                firstLineSvg,
                secondLineSvg,
                thirdLineSvg,
                "</svg>"
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        openingJson,
                        Base64.encode(bytes(finalSvg)),
                        '"}'
                    )
                )
            )
        );

        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return finalTokenUri;
    }

    function updateLaVieBoard(
        string memory firstLine,
        string memory secondLine,
        string memory thirdLine,
        uint256 amount
    ) external {
        require(amount > currentPrice, "not enough LaVx sent to update");
        require(
            LaVxToken.balanceOf(msg.sender) >= amount,
            "you don't own enough LaVx tokens!"
        );

        require(
            bytes(firstLine).length <= 50,
            "first line can be of 50 bytes max"
        );
        require(
            bytes(secondLine).length <= 50,
            "second line can be of 50 bytes max"
        );
        require(
            bytes(thirdLine).length <= 50,
            "third line can be of 50 bytes max"
        );

        storedFirstLine = firstLine;
        storedSecondLine = secondLine;
        storedThirdLine = thirdLine;

        LaVxToken.approve(payable(address(this)),amount);
        LaVxToken.transferFrom(msg.sender, payable(address(this)), amount);
        currentPrice = amount;

        emit LaVieBoardUpdated(
            firstLine,
            secondLine,
            thirdLine,
            amount,
            msg.sender
        );
    }

    function totalSupply() external pure returns (uint256) {
        return 1;
    }

    function getCurrentPrice() external view returns (uint256) {
        return currentPrice;
    }

    function withdraw(address payable sendToAddress, uint256 amount) external {
        require(msg.sender == ownerOf(1), "you are not the owner");
        require(
            amount <= LaVxToken.balanceOf(address(this)),
            "not enough balance"
        );
        LaVxToken.transferFrom(address(this), sendToAddress, amount);
    }
}
