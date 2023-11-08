pragma solidity ^0.8.9;
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../erc7254/IERC7254.sol";
import "../interface/IWETH.sol";
import "../interface/IRouterERC20ERC1155.sol";
import "../interface/ICreator.sol";
import "../library/TransferHelper.sol";

contract LaunchPad is ERC1155Holder {

    struct launchpad_data {
        address creator;
        address tokenPayment;
        uint tokenId;
        uint initial;
        uint softcap;
        uint hardcap;
        uint percentLock;
        uint price;
        uint priceListing;      
        uint startTime;
        uint endTime;
        uint durationLock;
        uint maxbuy;
        uint vestingTime;
        uint TGE;
        bool burnType;
        bool whiteList;
        bool vestingStatus;
    }

    uint public totalSoldout;
    uint public Denominator = 1000000;
    uint private _totalSupply;
    address public dml;
    address WETH;
    address NFT;
    address router;
    bool isListed = false;
    bool isWithdrawn = false;
    bool public softcapmet;
    
    mapping(address => bool) public admin;
    mapping(address => bool) public isWhitelisted;
    mapping(address => uint) public balanceOf;
    mapping(address => uint) public tokenReleased;

    launchpad_data public LaunchPadInfo;

    constructor(launchpad_data memory launchpad_information, address _nft, address _weth, address _router, uint totalSupply_) {
        // refund type: true: burn, false: refund
        // whitelist: true: enable, false: disable
        //  1% -> 10000
        LaunchPadInfo = launchpad_information;
        WETH = _weth;
        NFT = _nft;
        router = _router;
        _totalSupply = totalSupply_;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    modifier onlyCreator(){
         require(msg.sender == LaunchPadInfo.creator, "Only Creator");
        _;
    }  

    modifier onlyAdmin(){
        require(admin[msg.sender] || msg.sender == LaunchPadInfo.creator, "Only Admin or Creator");
        _;
    }

    modifier verifyAmount(uint _amount){
        require(totalSoldout + _amount <= LaunchPadInfo.hardcap, "Exceed amount");
        require(balanceOf[msg.sender] + _amount <= LaunchPadInfo.maxbuy);
        if(totalSoldout + _amount >= LaunchPadInfo.softcap) softcapmet = true;
        _;
    }
    
    modifier verifyWhiteList(){
        if(LaunchPadInfo.whiteList){
            require(isWhitelisted[msg.sender], "No whitelist");
        }
        _;
    }

    modifier verifyTimeClaimDml(){
        uint timeClaim = LaunchPadInfo.endTime + LaunchPadInfo.durationLock;
        require(timeClaim <= block.timestamp, "Waiting time");
        _;
    }

    modifier verifyTimeClaim(){
        require(block.timestamp > LaunchPadInfo.endTime, "Waiting end");
        _;
    }

    modifier verifyTimeBuy(){
        require(block.timestamp > LaunchPadInfo.startTime && block.timestamp <= LaunchPadInfo.endTime, "Sold out");
        _;
    }

    event Admin( address admin, bool status, uint blockTime);

    event WhiteList( address user, bool status, uint blockTime);

    event Buy( address user, uint amount, uint totalSold, uint blockTime);

    event Leave( address user, uint amount, uint totalSold, uint blockTime);

    event Released( address user, uint amount, uint blockTime);

    event Listing( address dml, uint totalTokenAddLiquidity, uint totalNFTAddLiquidity, uint blockTime);

    event ClaimDml( address dml, address creator, uint amount, uint blockTime);

    event ClaimReward( address dml, address[] tokenReward, address creator, uint blockTime);

    event Withdraw(address creator, uint amount, uint blockTime);

    function addAdmin(address[] memory _admin, bool[] memory _status) external onlyCreator() {
        for(uint i =0; i < _admin.length; i++){
            admin[_admin[i]] = _status[i];
            emit Admin(_admin[i], _status[i], block.timestamp);
        }
    }

    function addWhiteList(address[] memory _address, bool[] memory _status) external onlyAdmin(){
        require(LaunchPadInfo.whiteList, "LAUNCHPAD: WHITELIST_IS_DISABLE");
        require(_address.length == _status.length, "LAUNCHPAD: INPUT_WRONG");
        for(uint i = 0; i < _address.length; i++){
            isWhitelisted[_address[i]] = _status[i];
            emit WhiteList(_address[i], _status[i], block.timestamp);
        }
    }

    function buy(uint _amount) external verifyWhiteList() verifyTimeBuy() verifyAmount(_amount){
        uint amount = LaunchPadInfo.price * _amount;
        TransferHelper.safeTransferFrom(LaunchPadInfo.tokenPayment, msg.sender, address(this), amount);
        balanceOf[msg.sender] += _amount;
        totalSoldout += _amount;
        emit Buy(msg.sender, _amount, totalSoldout, block.timestamp);
    }

    function buyETH(uint _amount) external payable verifyWhiteList() verifyTimeBuy() verifyAmount(_amount){
        require(LaunchPadInfo.tokenPayment == WETH, "LAUNCHPAD: WETH_WRONG");
        uint amount = LaunchPadInfo.price * _amount;
        require(msg.value >= amount, "LAUNCHPAD: BUY_WRONG");
        IWETH(WETH).deposit{value: amount}();
        if (msg.value > amount) TransferHelper.safeTransferETH(msg.sender, msg.value - amount);
        balanceOf[msg.sender] += _amount;
        totalSoldout += _amount;
        emit Buy(msg.sender, _amount, totalSoldout, block.timestamp);
    }

    function leave(uint amount) external {
        require(!softcapmet, "LAUNCHPAD: SOFTCAP_WRONG");
        require(balanceOf[msg.sender] >= amount, "LAUNCHPAD: BALANCEOF_WRONG");
        balanceOf[msg.sender] -= amount;
        totalSoldout -= amount;
        TransferHelper.safeTransfer(LaunchPadInfo.tokenPayment, msg.sender, LaunchPadInfo.price * amount);
        emit Leave(msg.sender, amount, totalSoldout, block.timestamp);
    }

     function release() external verifyTimeClaim(){
        if(!isListed) listing();
        require(isListed, "LAUNCHPAD: WAITING_LISTING");
        require(softcapmet, "LAUNCHPAD: SOFTCAP_WRONG");
        uint256 amount = releasable(msg.sender);
        tokenReleased[msg.sender] += amount;
        TransferHelper.safeTransferFromERC1155(NFT, address(this), msg.sender, LaunchPadInfo.tokenId, amount, bytes(''));
        emit Released(msg.sender, amount, block.timestamp);
    }

    function listing() public verifyTimeClaim(){
        require(softcapmet, "LAUNCHPAD: SOFTCAP_WRONG");
        uint amount = totalSoldout * LaunchPadInfo.price * LaunchPadInfo.percentLock / Denominator;
        uint totalTokenAddPool = getBalance(amount);
        uint totalNFTAddPool = totalTokenAddPool / LaunchPadInfo.priceListing;
        require(totalTokenAddPool > 0 && totalNFTAddPool > 0, "LAUNCHPAD: LIQUIDITY_WRONG");
        uint totalRemaining = totalSupply() - LaunchPadInfo.initial - totalSoldout - totalNFTAddPool;
        if(LaunchPadInfo.burnType && totalRemaining > 0) ICreator(NFT).burn(LaunchPadInfo.tokenId, totalRemaining);
        if(!LaunchPadInfo.burnType && totalRemaining > 0) TransferHelper.safeTransfer(LaunchPadInfo.tokenPayment, LaunchPadInfo.creator, totalRemaining);
        if(LaunchPadInfo.initial > 0) TransferHelper.safeTransfer(LaunchPadInfo.tokenPayment, LaunchPadInfo.creator, LaunchPadInfo.initial);
        TransferHelper.safeTransfer(LaunchPadInfo.tokenPayment, router, totalTokenAddPool);
        TransferHelper.safeTransferFromERC1155(NFT, address(this) , router, LaunchPadInfo.tokenId, totalNFTAddPool, bytes(''));
        dml = IRouterERC20ERC1155(router).launchpadAddLiquidity(LaunchPadInfo.tokenPayment, NFT, LaunchPadInfo.tokenId, totalTokenAddPool, totalNFTAddPool, 0, address(this), block.timestamp + 60*60);
        isListed = true;
        emit Listing(dml, totalTokenAddPool, totalNFTAddPool, block.timestamp);
    }

    function claimDml() external onlyCreator() verifyTimeClaimDml(){
        uint256 balance = IERC7254(dml).balanceOf(address(this));
        TransferHelper.safeTransfer(dml, msg.sender, balance);
        emit ClaimDml(dml, msg.sender, balance, block.timestamp);
    }

    function claimReward() public onlyCreator(){
        address[] memory tokenReward = IERC7254(dml).tokenReward();
        IERC7254(dml).getReward(tokenReward, msg.sender);
        emit ClaimReward(dml, tokenReward, msg.sender, block.timestamp);
    }

    function withdraw() external onlyCreator(){
        require(block.timestamp >= LaunchPadInfo.endTime, "LAUNCHPAD: ENDTIME_WRONG");
        require(softcapmet, "LAUNCHPAD: SOFTCAP_WRONG");
        require(!isWithdrawn, "LAUNCHPAD: WITHDRAW_WRONG");
        uint amount = totalSoldout * LaunchPadInfo.price * (Denominator - LaunchPadInfo.percentLock) / Denominator;
        uint amountWithdraw = getBalance(amount);
        isWithdrawn = true;
        TransferHelper.safeTransfer(LaunchPadInfo.tokenPayment, LaunchPadInfo.creator, amountWithdraw);
        emit Withdraw(LaunchPadInfo.creator, amountWithdraw, block.timestamp);
    }

    function totalSupply() public view returns(uint){
        return _totalSupply;
    }

    function startVesting() public view returns(uint256){
        return LaunchPadInfo.endTime;
    }

    function duration() public view returns(uint256){
        return LaunchPadInfo.vestingTime;
    }

    function released(address _user) public view returns(uint){
        return tokenReleased[_user];
    }

    function releasable(address _user) public view returns(uint){
        return _vestingSchedule(balanceOf[_user], block.timestamp) - released(_user);
    }

    function getBalance(uint _amount) internal view returns(uint){
        uint amount = (IERC7254(LaunchPadInfo.tokenPayment).balanceOf(address(this)) > _amount) ? _amount : IERC7254(LaunchPadInfo.tokenPayment).balanceOf(address(this));
        return amount;
    }

    function _vestingSchedule(uint totalAllocation, uint timestamp) internal view returns(uint){
        if (timestamp < startVesting() || !softcapmet) {
            return 0;
        } else if ( (timestamp > startVesting() + duration()) || !LaunchPadInfo.vestingStatus) {
            return totalAllocation;
        } else {
            uint TGE_Amount = totalAllocation * LaunchPadInfo.TGE / Denominator;
            return ( TGE_Amount + (totalAllocation - TGE_Amount) * (timestamp - startVesting()) / duration());
        }
    }

}