// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;
interface IDMLTokenERC20ERC1155 {
    function getReserves() external view returns (uint256 _reserveerc, uint256 _reservenft);
    function mint(address to) external returns (uint256 liquidity) ;
    function transferFrom(address from, address to, uint256 amount ) external returns (bool);
    function burn(address to) external returns (uint amounterc, uint amountnft);
    function updateReward(address[] memory token, uint256[] memory amount) external;
    function getPool() external view returns (address);
    function swap(uint amountercOut, uint amountnftOut, address to, address from) external;
}