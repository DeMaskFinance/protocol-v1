// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Referral is Ownable{

    address charity;

    mapping(address => address) public sponsor;
    mapping(address => address[]) public ref;

    event UpdateCharity(
        address charity,
        uint blockTime
    );
    
    event Referee (
        address sponsor,
        address user,
        uint blockTime
    );

    constructor(address _charity){
        charity = _charity;
        emit UpdateCharity(_charity, block.timestamp);
    }
  
    function changeCharity(address _charity) external onlyOwner {
        require(_charity != address(0));
        charity = _charity;
        emit UpdateCharity(_charity, block.timestamp);
    }
    
    function referee(address _sponsor) external {
        require(msg.sender != _sponsor && sponsor[_sponsor] != msg.sender && sponsor[msg.sender] == address(0) && _sponsor != address(0));
        sponsor[msg.sender] = _sponsor;
        ref[_sponsor].push(msg.sender);
        emit Referee(_sponsor, msg.sender, block.timestamp);
    }

    function getSponsor(address user) external view returns(address){
        return sponsor[user];
    }

    function getRef(address user) external view returns(address[] memory) {
        return ref[user];
    }

    function getCharity() external view returns(address){
        return charity;
    }
    
    function getReceiver(address user) external view returns(address){
        address receiver = (sponsor[user] == address(0)) ? charity : sponsor[user];
        return receiver;
    }
}