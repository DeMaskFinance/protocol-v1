pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/ITokenList.sol";
import "./LaunchPad.sol";

contract FactoryLaunchpad is Ownable {
    address public WETH;
    address public tokenList;

    constructor(address _WETH, address _tokenList) {
        WETH = _WETH;
        tokenList = _tokenList;
    }

    modifier isCheckToken(address token) {
        require(token == WETH || ITokenList(tokenList).getState(token), "FACTORY: TOKENLIST_WRONG");
        _;
    }

    event CreateLaunchpad(
        address tokenPayment,
        address nft,
        uint256 tokenId,
        uint price,
        uint softcap,
        uint hardcap,
        uint startTime,
        uint endTime,
        uint tge,
        uint vesting,
        uint purchaseLimit,
        uint blockTime
    );

    function createLaunchpad(
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
        ) external isCheckToken(_tokenPayment) onlyOwner(){
            emit CreateLaunchpad(_tokenPayment, _nft, _tokenId, _price, _softcap, _hardcap, _startTime, _endTime, _tge, _vesting, _purchaseLimit, block.timestamp);
    }

    function withdraw(address _launchpad) external onlyOwner(){

    }
}