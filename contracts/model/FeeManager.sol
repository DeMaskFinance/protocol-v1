pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IReferral.sol";
import "../interface/IRoyaltyEngineV1.sol";

interface IDMLToken {
    function getPool() external view returns (address); 
}

contract FeeManager is Ownable {

    constructor(address _protocolReceiver, address _referralContract, address _royatyEngine){
        protocolReceiver = _protocolReceiver;
        referralContract = _referralContract;
        royaltyEngine = _royatyEngine;
    }
   
    address public protocolReceiver;
    address public referralContract;
    address public royaltyEngine;
    bool public isProtocolFee;
    uint public MAX_POINT = 30000; // 3%
    uint private protocolPoint = 5000;
    uint private referralPoint = 1000;
    uint private liquidityPoint = 9000;
    uint public Denominator = 1000000;

    event UpdateFee(
        address owner,
        uint protocolPoint,
        uint referralPoint,
        uint liquidityPoint,
        bool isProtocolFee,
        uint blockTime
    );
    event UpdateProtocolReceiver(
        address owner,
        address protocolReceiver,
        uint blockTime
    );

    event UpdateRoyaltyEngine(
        address royaltyEngine,
        uint blockTime
    );

    function updateProtocolReceiver(address _protocolReceiver) external onlyOwner(){
        require(_protocolReceiver != address(0), "FEEMANAGER: PROTOCOL_RECEIVER_WRONG");
        protocolReceiver = _protocolReceiver;
        emit UpdateProtocolReceiver(msg.sender, _protocolReceiver, block.timestamp);
    }

    function updateRoyaltyEngine(address _royaltyEngine) external onlyOwner(){
        require(_royaltyEngine != address(0), "FEEMANAGER: ROYALTY_ENGINE_WRONG");
        royaltyEngine = _royaltyEngine;
        emit UpdateRoyaltyEngine(_royaltyEngine, block.timestamp);
    }

    function updateFee(
        uint _protocolPoint,
        uint _referralPoint,
        uint _liquidityPoint,
        bool statusProtocolFee
    ) external onlyOwner(){
        require(
            _protocolPoint <= MAX_POINT &&
            _referralPoint <= MAX_POINT &&
            _liquidityPoint <= MAX_POINT,
            "FeeManager: FEE_WRONG"
        );
        protocolPoint = _protocolPoint;
        referralPoint = _referralPoint;
        liquidityPoint = _liquidityPoint;
        isProtocolFee = statusProtocolFee;
        emit UpdateFee(msg.sender, _protocolPoint, _referralPoint, _liquidityPoint, statusProtocolFee , block.timestamp);
    }

    function getProtocolReceiver() public view returns(address){
        return protocolReceiver;
    }

    function getProtocolPoint() public view returns(uint){
        uint point = isProtocolFee ? protocolPoint : 0;
        return point;
    }

    function getReferralPoint() public view returns(uint){
        return referralPoint;
    }

    function getLiquidityPoint() public view returns(uint){
        return liquidityPoint;
    }

    function getFeeLiquidity(uint256 amount) public view returns(uint256){
        return amount * getLiquidityPoint() / Denominator;
    }

    function getFeeProtocol(uint256 amount) public view returns(uint256){
        return amount * getProtocolPoint() / Denominator;
    }

    function getFeeReferral(uint256 amount) public view returns(uint256){
        return amount * getReferralPoint() / Denominator;
    }

    function getFeeRoyalty(address tokenAddress, uint256 tokenId, uint256 value) public view returns(uint){
        uint256 totalAmount = 0;
        (, uint256[] memory amounts) = IRoyaltyEngineV1(royaltyEngine).getRoyaltyView(tokenAddress, tokenId, value);
        for(uint256 i = 0; i < amounts.length; i++){
            totalAmount += amounts[i];
        }
        return totalAmount; 
    }

    function getDetailsProtocol(uint256 amount) external view returns(address receiver, uint256 value) {
        receiver = protocolReceiver;
        value = getFeeProtocol(amount);
    }

    function getDetailsReferral(address user, uint256 amount) external view returns(address receiver, uint256 value) {
        receiver = IReferral(referralContract).getReceiver(user);
        value = getFeeReferral(amount);
    }

    function getDetailsLiquidity(address dml, uint256 amount) external view returns(address receiver, uint256 value) {
        receiver = IDMLToken(dml).getPool();
        value = getFeeLiquidity(amount);
    }

    function getDetailsRoyalty(address tokenAddress, uint256 tokenId, uint256 value) external view returns(address payable[] memory recipients, uint256[] memory amounts) {
        (recipients, amounts) = IRoyaltyEngineV1(royaltyEngine).getRoyaltyView(tokenAddress, tokenId, value);
    }

    function getTotalFee(uint amount, address tokenAddress, uint256 tokenId) external view returns(uint){
        uint fee = getFeeProtocol(amount) + getFeeReferral(amount) + getFeeLiquidity(amount) + getFeeRoyalty(tokenAddress, tokenId, amount);
        return fee;
    }

    function getTotalFeeMultiTokenId(uint amount, address tokenAddress, uint256[] memory tokenId) external view returns(uint){
        uint feeRoyalty; 
        for(uint i = 0; i < tokenId.length; i++){
            feeRoyalty += getFeeRoyalty(tokenAddress, tokenId[i], amount / tokenId.length);
        }
        uint fee = getFeeProtocol(amount) + getFeeReferral(amount) + getFeeLiquidity(amount) + feeRoyalty;
        return fee;
    }

    function getFee(uint amount, address dml, address tokenAddress, uint256 tokenId, address user) external view returns(address[] memory, uint256[] memory){
        (address payable[] memory recipients, uint256[] memory amounts) = IRoyaltyEngineV1(royaltyEngine).getRoyaltyView(tokenAddress, tokenId, amount);
        address[] memory feeAddress = new address[](3 + recipients.length);
        uint256[] memory feeAmount = new uint256[](3 + amounts.length);
        feeAddress[0] = protocolReceiver;
        feeAddress[1] = IReferral(referralContract).getReceiver(user);
        feeAddress[2] = IDMLToken(dml).getPool();
        feeAmount[0] = getFeeProtocol(amount);
        feeAmount[1] = getFeeReferral(amount);
        feeAmount[2] = getFeeLiquidity(amount);
        for(uint256 i = 0; i < recipients.length; i++){
            if(amounts[i] > 0 && recipients[i] != address(0)){
                feeAddress[3 + i] = recipients[i];
                feeAmount[3 + i] = amounts[i];
            }
        }
        return (feeAddress, feeAmount);
    }

}

