pragma solidity >=0.8.0;

interface IERC20 {
    function mint(address to, uint256 amount) external;

    function _transferOwnership(address newOwner) external;
}
