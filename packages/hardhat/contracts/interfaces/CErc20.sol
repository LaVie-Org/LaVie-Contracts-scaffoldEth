pragma solidity ^0.8.4;

//SPDX-License-Identifier: MIT

interface CErc20 {
    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);
}
