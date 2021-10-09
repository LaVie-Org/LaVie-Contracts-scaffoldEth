pragma experimental ABIEncoderV2;
pragma solidity ^0.8.4;
//SPDX-License-Identifier: MIT

interface DepositToVesting{

    function  getVestID(address addr, uint64 depositID) external returns(uint64 vestingID);

}


