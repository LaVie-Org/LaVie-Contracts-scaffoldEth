//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface DInterestInterface {
    function deposit(uint256 depositAmount, uint64 maturationTimestamp)
        external
        returns (uint64 depositID);

    function withdraw(
        uint64 depositID,
        uint256 virtualTokenAmount,
        bool early
    ) external returns (uint256 withdrawnStablecoinAmount);
}