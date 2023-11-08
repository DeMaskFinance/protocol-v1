pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../library/TransferHelper.sol";

contract Pool is AccessControl {
    bytes32 public constant POOL_ROLE = keccak256("POOL_ROLE");
    address public tokenReward;
    address public weth;

    constructor(address _dml, address _tokenReward, address _weth){
        _setupRole(POOL_ROLE, _dml);  
        tokenReward = _tokenReward;
        weth = _weth;
    }
    
    event TransferToken(
        address token,
        address receiver,
        uint256 amount,
        uint256 timeStamp
    );

    receive() external payable {}

    function transferToken(address _to, uint256 _amount) external onlyRole(POOL_ROLE) {
        uint256 balancePool = (tokenReward == weth) ? address(this).balance : IERC20(tokenReward).balanceOf(address(this));
        uint reward = (_amount > balancePool) ? balancePool : _amount;
        if(reward > 0){
            if(tokenReward == weth){
                TransferHelper.safeTransferETH(_to, reward);
                emit TransferToken(tokenReward, _to, reward, block.timestamp); 
            }else{
               TransferHelper.safeTransfer(tokenReward, _to, reward); 
               emit TransferToken(tokenReward, _to, reward, block.timestamp); 
            }
        }
    }
}