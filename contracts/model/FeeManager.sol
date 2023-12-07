pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IReferral.sol";


interface IDMLToken {
    function getPool() external view returns (address); 
}

contract FeeManager is Ownable {

    constructor(address _protocolReceiver, address _referralContract){
        protocolReceiver = _protocolReceiver;
        referralContract = _referralContract;
    }
   
    address public protocolReceiver;
    address public referralContract;
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

    event UpdateReferralContract(
        address referral,
        uint blockTime
    );

    function updateProtocolReceiver(address _protocolReceiver) external onlyOwner(){
        require(_protocolReceiver != address(0), "FEEMANAGER: PROTOCOL_RECEIVER_WRONG");
        protocolReceiver = _protocolReceiver;
        emit UpdateProtocolReceiver(msg.sender, _protocolReceiver, block.timestamp);
    }

    function updateReferralContract(address _referral) external onlyOwner() {
        require(_referral != address(0),"FEEMANAGER: REFERRAL_CONTRACT_WRONG");
        referralContract = _referral;
        emit UpdateReferralContract(_referral, block.timestamp);
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

    function getTotalFee(uint amount) external view returns(uint){
        uint fee = getFeeProtocol(amount) + getFeeReferral(amount) + getFeeLiquidity(amount);
        return fee;
    }

    function getFee(uint amount, address dml, address user) external view returns(address[] memory, uint256[] memory){
        address[] memory feeAddress = new address[](3);
        uint256[] memory feeAmount = new uint256[](3);
        feeAddress[0] = protocolReceiver;
        feeAddress[1] = IReferral(referralContract).getReceiver(user);
        feeAddress[2] = IDMLToken(dml).getPool();
        feeAmount[0] = getFeeProtocol(amount);
        feeAmount[1] = getFeeReferral(amount);
        feeAmount[2] = getFeeLiquidity(amount);
        return (feeAddress, feeAmount);
    }
}

