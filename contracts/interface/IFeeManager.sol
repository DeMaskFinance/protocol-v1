pragma solidity ^0.8.0;

interface IFeeManager {
    function getProtocolReceiver() external view returns(address);
    function getProtocolPoint() external view returns(uint);
    function getReferralPoint() external view returns(uint);
    function getLiquidityPoint() external view returns(uint);
    function getFeeLiquidity(uint amount) external view returns(uint);
    function getFeeProtocol(uint amount) external view returns(uint);
    function getFeeReferral(uint amount) external view returns(uint);
    function getFeeRoyalty(address tokenAddress, uint256 tokenId, uint256 value) external view returns(uint);
    function getDetailsProtocol(uint256 amount) external view returns(address receiver, uint256 value);
    function getDetailsReferral(address user, uint256 amount) external view returns(address receiver, uint256 value);
    function getDetailsLiquidity(address dml, uint256 amount) external view returns(address receiver, uint256 value);
    function getDetailsRoyalty(address tokenAddress, uint256 tokenId, uint256 value) external view returns(address[] memory recipients, uint256[] memory amounts);
    function getTotalFee(uint amount, address tokenAddress, uint256 tokenId) external view returns(uint);
    function getTotalFeeMultiTokenId(uint amount, address tokenAddress, uint256[] memory tokenId) external view returns(uint);
    function getFee(uint amount, address dml, address tokenAddress, uint256 tokenId, address user) external view returns(address[] memory feeAddress, uint[] memory feeAmount);
}