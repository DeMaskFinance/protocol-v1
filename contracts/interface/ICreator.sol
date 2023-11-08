pragma solidity ^0.8.0;

interface ICreator {
    function burn(uint _id, uint _amount) external;
    function existLaunchPad(address _launchpad) external view returns (bool);
    function getRouter() external view returns(address);
    
}