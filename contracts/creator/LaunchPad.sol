pragma solidity ^0.8.9;
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/IWETH.sol";
import "../library/TransferHelper.sol";

contract LaunchPad is ERC1155Holder {

    // buy, claim, leave, withdraw
    uint256 public tokenId;
    uint public price;
    uint public softcap;
    uint public hardcap;
    uint public startTime;
    uint public endTime;
    uint public tge;
    uint public vesting;
    uint public purchaseLimit;
    uint public totalSoldout;
    uint public Denominator = 1000000;
    address public WETH;
    address public NFT;
    address public tokenPayment;
    address public creator;
    bool public isWithdrawn = false;
    bool public softcapmet;
    
    mapping(address => uint) public balanceOf;
    mapping(address => uint) public tokenReleased;

    constructor(
        address _weth,
        address _tokenPayment, 
        address _nft,
        uint256 _tokenId, 
        uint _price,
        uint _softcap, 
        uint _hardcap, 
        uint _startTime,
        uint _endTime,
        uint _tge, 
        uint _vesting, 
        uint _purchaseLimit
    ) {
        WETH = _weth;
        tokenPayment = _tokenPayment;
        NFT = _nft;
        tokenId = _tokenId;
        price = _price;
        softcap = _softcap;
        hardcap = _hardcap;
        tge = _tge;
        vesting = _vesting;
        purchaseLimit = _purchaseLimit;
        startTime = _startTime;
        endTime = _endTime;
        creator = msg.sender;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    modifier onlyCreator(){
        require(msg.sender == creator, "LAUNCHPAD: CREATOR_WRONG");
        _;
    }

    modifier verifyTransactionAmount(uint _amount){
        require( (totalSoldout + _amount) * price <= hardcap, "LAUNCHPAD: AMOUNT_WRONG");
        require(balanceOf[msg.sender] + _amount <= purchaseLimit, "LAUNCHPAD: PURCHASE_LIMIT_WRONG");
        if( (totalSoldout + _amount) * price >= softcap) softcapmet = true;
        _;
    }

    modifier verifyTimeClaimForUser(){
        require(block.timestamp > endTime, "LAUNCHPAD: WAITING_FOR_LAUNCHPAD_TO_BE_END");
        _;
    }

    modifier verifyTimeBuyForUser(){
        require(block.timestamp > startTime && block.timestamp <= endTime, "LAUNCHPAD: WAITING_FOR_LAUNCHPAD_TO_BE_OPENED");
        _;
    }

    event Buy( address user, uint amount, uint totalSold, uint blockTime);

    event Leave( address user, uint amount, uint totalSold, uint blockTime);

    event Released( address user, uint amount, uint blockTime);

    event Withdraw(address creator, uint amount, uint blockTime);

    function buy(uint _amount) external payable verifyTimeBuyForUser() verifyTransactionAmount(_amount){
        uint totalOrderValue = price * _amount;
        if(tokenPayment == WETH){
            require(msg.value >= totalOrderValue, "LAUNCHPAD: BUY_WRONG");
            if (msg.value > totalOrderValue) TransferHelper.safeTransferETH(msg.sender, msg.value - totalOrderValue);

        }else{
           TransferHelper.safeTransferFrom(tokenPayment, msg.sender, address(this), totalOrderValue); 
        }
        balanceOf[msg.sender] += _amount;
        totalSoldout += _amount;
        emit Buy(msg.sender, _amount, totalSoldout, block.timestamp);
    }

    function leave(uint amount) external verifyTimeClaimForUser() {
        require(!softcapmet, "LAUNCHPAD: SOFTCAP_WRONG");
        require(balanceOf[msg.sender] >= amount && amount > 0, "LAUNCHPAD: BALANCEOF_WRONG");
        balanceOf[msg.sender] -= amount;
        totalSoldout -= amount;
        if(tokenPayment == WETH){
            TransferHelper.safeTransferETH(msg.sender, price * amount);
        }else {
            TransferHelper.safeTransfer(tokenPayment, msg.sender, price * amount);
        }     
        emit Leave(msg.sender, amount, totalSoldout, block.timestamp);
    }

    function release() external verifyTimeClaimForUser(){
        require(softcapmet, "LAUNCHPAD: SOFTCAP_WRONG");
        uint256 amount = releasable(msg.sender);
        require(amount > 0, "LAUNCHPAD: AMOUNT_WRONG");
        tokenReleased[msg.sender] += amount;
        TransferHelper.safeTransferFromERC1155(NFT, address(this), msg.sender, tokenId, amount, bytes(''));
        emit Released(msg.sender, amount, block.timestamp);
    }

    function withdraw(address receiver) external onlyCreator(){
        require(block.timestamp >= endTime, "LAUNCHPAD: ENDTIME_WRONG");
        require(softcapmet, "LAUNCHPAD: SOFTCAP_WRONG");
        require(!isWithdrawn, "LAUNCHPAD: WITHDRAW_WRONG");
        uint amount = getBalance();
        isWithdrawn = true;
        if(tokenPayment == WETH){
            TransferHelper.safeTransferETH(receiver, amount);
        }else{
            TransferHelper.safeTransfer(tokenPayment, receiver, amount);
        }
        emit Withdraw(receiver, amount, block.timestamp);
    }

    function startVesting() public view returns(uint256){
        return endTime;
    }

    function duration() public view returns(uint256){
        return vesting;
    }

    function released(address _user) public view returns(uint){
        return tokenReleased[_user];
    }

    function releasable(address _user) public view returns(uint){
        return _vestingSchedule(balanceOf[_user], block.timestamp) - released(_user);
    }

    function getBalance() internal view returns(uint){
        uint amount = (tokenPayment == WETH) ? address(this).balance : IERC20(tokenPayment).balanceOf(address(this));
        return amount;
    }

    function _vestingSchedule(uint totalAllocation, uint timestamp) internal view returns(uint){
        if (timestamp < startVesting() || !softcapmet) {
            return 0;
        } else if ( timestamp > (startVesting() + duration()) ) {
            return totalAllocation;
        } else {
            uint TGE_Amount = totalAllocation * tge / Denominator;
            return ( TGE_Amount + (totalAllocation - TGE_Amount) * (timestamp - startVesting()) / duration());
        }
    }

}