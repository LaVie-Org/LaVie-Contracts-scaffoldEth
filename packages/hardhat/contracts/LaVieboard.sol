// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

import {Base64} from "./libraries/Base64.sol";

contract TheLaVieBoard is ERC721URIStorage {
    uint256 currentPrice = 0;

    string public storedFirstLine = "";
    string public storedSecondLine = "";
    string public storedThirdLine = "";

    mapping(uint256 => string[5]) public idToBoardInfo;
    uint256 public index = 0;

    address public owner;
    address private constant laVxAddress =
        0x71b4f145617410eE50DC26d224D202e9278D71f1;

    ERC777 private LaVxToken;

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
        LaVxToken = ERC777(laVxAddress);
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

        LaVxToken.transferFrom(msg.sender, payable(address(this)), amount);
        currentPrice = amount;

        string memory addressString = toAsciiString(msg.sender);
        string memory amountString = uint2str(amount);

        idToBoardInfo[index] = [
            addressString,
            firstLine,
            secondLine,
            thirdLine,
            amountString
        ];
        index++;

        emit LaVieBoardUpdated(
            firstLine,
            secondLine,
            thirdLine,
            amount,
            msg.sender
        );
    }

    function fetchBoardInfo() external view returns (string[5][] memory) {
        string[5][] memory  info = new string[5][](index);
        for (uint256 i = 0; i < index; i++) {
            info[i][0] = (idToBoardInfo[i][0]);
            info[i][1] = (idToBoardInfo[i][1]);
            info[i][2] = (idToBoardInfo[i][2]);
            info[i][3] = (idToBoardInfo[i][3]);
            info[i][4] = (idToBoardInfo[i][4]);


            console.log(idToBoardInfo[4][i]);
        }
        return info;
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
        LaVxToken.transfer(sendToAddress, amount);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
