//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVesting02{

    function withdraw(uint64 vestID) external returns(uint256 withdrawAmount);
}