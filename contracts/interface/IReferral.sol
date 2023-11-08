interface IReferral {
    function getSponsor(address user) external view returns(address);
    function getRef(address user) external view returns(address[] memory);
    function getFee() external view returns(uint);
    function getCharity() external view returns(address);
    function getReceiver(address user) external view returns(address);
}