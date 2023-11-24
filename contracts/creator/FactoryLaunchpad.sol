pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/ITokenList.sol";
import "./LaunchPad.sol";

contract FactoryLaunchpad is Ownable {

    address public WETH;
    address public tokenList;
    uint public Denominator = 1000000;

    constructor(address _WETH, address _tokenList) {
        WETH = _WETH;
        tokenList = _tokenList;
    }

    modifier isCheckToken(address token) {
        require(token == WETH || ITokenList(tokenList).getState(token), "FACTORYLAUNCHPAD: TOKENLIST_WRONG");
        _;
    }

    event CreateLaunchpad(
        address launchpad,
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
            require(_endTime > block.timestamp && _endTime > _startTime, "FACTORYLAUNCHPAD: TIME_WRONG");
            require(_hardcap >= _softcap && _softcap > _price, "FACTORYLAUNCHPAD: CAP_WRONG");
            require(_tge <= Denominator, "FACTORYLAUNCHPAD: TGE_WRONG");
            require(_purchaseLimit >= 1, "FACTORYLAUNCHPAD: PURCHASELIMIT_WRONG");
            LaunchPad launchpad = new LaunchPad(
                WETH,
                _tokenPayment,
                _nft,
                _tokenId,
                _price,
                _softcap,
                _hardcap,
                _startTime,
                _endTime,
                _tge,
                _vesting,
                _purchaseLimit
            );
            emit CreateLaunchpad( address(launchpad) ,_tokenPayment, _nft, _tokenId, _price, _softcap, _hardcap, _startTime, _endTime, _tge, _vesting, _purchaseLimit, block.timestamp);
    }

    function withdraw(address _launchpad) external onlyOwner(){
        LaunchPad(payable(_launchpad)).withdraw(msg.sender);
    }
}