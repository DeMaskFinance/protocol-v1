// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract tokenerc20 is ERC20, Ownable {
    constructor() ERC20("TEST", "TEST") {
         _mint(msg.sender, 1000000000*1e18);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}