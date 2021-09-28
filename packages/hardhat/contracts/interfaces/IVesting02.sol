//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract IVesting02{
    mapping(address => mapping(uint64 => uint64)) public depositIDToVestID;

    function getVestID(address poolAddress, uint64 depositID) external view returns(uint64){
        return depositIDToVestID[poolAddress][depositID];
    }

    function withdraw(uint64 vestID) external returns(uint256 withdrawAmount){

    }
}