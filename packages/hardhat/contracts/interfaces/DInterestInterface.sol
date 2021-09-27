//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract DInterestInterface {

  function deposit(uint256 depositAmount, uint64 maturationTimestamp) public returns (uint64 depositID){}

   function withdraw(
        uint64 depositID,
        uint256 virtualTokenAmount,
        bool early
    )public returns (uint256 withdrawnStablecoinAmount) {}
} 