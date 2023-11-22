pragma solidity ^0.8.0;

interface IMint {
    function mint(address account, uint tokenId, uint amount, uint96 royaltiesFee, bytes memory data, string memory url) external;
    function burn(uint _id, uint _amount) external;
}