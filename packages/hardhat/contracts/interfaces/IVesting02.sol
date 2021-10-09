//SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;

pragma solidity ^0.8.4;

interface IVesting02 {
    function withdraw(uint64 vestID) external returns (uint256 withdrawAmount);

    function getVestID(address addr, uint64 depositID)
        external
        returns (uint64 vestingID);
}
