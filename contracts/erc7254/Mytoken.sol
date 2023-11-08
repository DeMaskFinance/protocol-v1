// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC7254.sol";
contract Mytoken is ERC7254  {
    constructor() ERC7254("Mytoken", "MY", 0x4A90D5aE01F03B650cdc8D3A94358F364D98d096) {
        _mint(msg.sender, 10000000*1e18);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function add(address[] memory tokenReward) external {
        _add(tokenReward);
    }
}