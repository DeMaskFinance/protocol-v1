// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "../erc7254/ERC7254.sol";
contract DeMask is ERC7254 {
    constructor(address token) ERC7254("DeMask", "DEM", token) {
        _mint(msg.sender, 1000000000*1e18);
    }
}