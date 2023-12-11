pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import '../erc7254/ERC7254.sol';
import "../model/Pool.sol";
import "../library/SafeMath.sol";
import "../library/TransferHelper.sol";
import "../interface/IFeeManager.sol";
import "../interface/IWETH.sol";
import "../interface/ITokenList.sol";
import "../interface/IRoyaltyEngineV1.sol";

contract DMLTokenERC20ERC721 is ERC7254, ERC721Holder, ReentrancyGuard {

    using SafeMath for uint;
    address public token;
    address public NFT;
    address public WETH;
    address public router;
    uint public reserveToken;
    uint public reserveNFT;
    uint public kLast;
    Pool private pool;
    IFeeManager public feeManager;
    uint public Denominator = 1000000;
    
    constructor(
        address _router,
        address _token,
        address _NFT,
        address _feeManager,
        address _weth
    ) ERC7254("DeMask Liquidity Token ERC20-ERC721", "DML", _token){
        token = _token;
        NFT = _NFT;
        router = _router;
        pool= new Pool(address(this), _token, _weth);
        feeManager = IFeeManager(_feeManager);
        WETH = _weth;
    }

    receive() external payable {}

    event Mint(address indexed sender, uint amountERC, uint amountNFT);
    event Sync(uint reserveToken, uint reserveNFT);
    event Burn(address indexed sender, uint amountERC, uint amountNFT, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event SwapNFT(address to, uint[] tokenId, uint blockTime);

    modifier onlyRouter(){
         require(msg.sender == router, "Only Router");
        _;
    }   

    function updateReward(address[] memory _token, uint256[] memory _amount) public virtual override onlyRouter() {
        require(_token.length == _amount.length, "ERC7254: token and amount length mismatch");
        if(totalSupply() != 0){
            for( uint i = 0; i < _token.length; ++i){
                _updateRewardPerShare(_token[i], _amount[i]);
            }
        }        
    }

    function feeToProtocol() public view returns(address){
        return feeManager.getProtocolReceiver();
    }

    function getReward(address[] memory _token, address to) public nonReentrant virtual override {
        address owner = _msgSender();
        for( uint i = 0; i < _token.length; ++i){
            UserInformation memory user = informationOf(_token[i],owner);
            uint reward = balanceOf(owner) * getRewardPerShare(token) + user.inReward - user.withdraw - user.outReward;
            _withdraw(_token[i], owner, reward);
            if(reward / MAX > 0){
                pool.transferToken(to, reward / MAX );
            }  
            emit GetReward(owner, to, reward);
        }
    }

    function getBalanceToken() internal view returns(uint){
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
        );
        require(success);
        return abi.decode(data, (uint));
    }

    function getBalanceNFT() internal view returns(uint){
        (bool success, bytes memory data) = NFT.staticcall(
            abi.encodeWithSelector(IERC721.balanceOf.selector, address(this))
        );
        require(success);
        return abi.decode(data, (uint));
    }

    function getReserves() public view returns (uint _reserveToken, uint _reserveNFT){
        _reserveToken = reserveToken;
        _reserveNFT = reserveNFT;
    }
    
    function getPool() public view returns (address){
        return address(pool);
    }

    function mint(address to) external nonReentrant returns (uint liquidity) {
        (uint _reserveToken, uint _reserveNFT) = getReserves();
        uint balanceToken = getBalanceToken();
        uint balanceNFT = getBalanceNFT();
        uint amountERC = balanceToken.sub(_reserveToken);
        uint amountNFT = balanceNFT.sub(_reserveNFT);

        bool feeOn = _mintFee(_reserveToken, _reserveNFT);
        uint _totalSupply = totalSupply();
        if(_totalSupply == 0){
            liquidity = Math.sqrt(amountERC.mul(amountNFT));
        } else {
            liquidity = Math.min(amountERC.mul(_totalSupply) / _reserveToken, amountNFT.mul(_totalSupply) / _reserveNFT);
        }

        require(liquidity > 0, 'DEMASK: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balanceToken, balanceNFT);
        if (feeOn) kLast = uint(reserveToken).mul(reserveNFT); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amountERC, amountNFT);
    }

    function burn(address to, uint256[] memory tokenId) external nonReentrant returns (uint amountERC, uint amountNFT) {
        (uint _reserveToken, uint _reserveNFT) = getReserves();
        uint balanceToken = getBalanceToken();
        uint balanceNFT = getBalanceNFT();
        uint liquidity = balanceOf(address(this));
        bool feeOn = _mintFee(_reserveToken, _reserveNFT);
        uint _totalSupply = totalSupply();
        amountERC = liquidity.mul(balanceToken) / _totalSupply;
        amountNFT = liquidity.mul(balanceNFT) / _totalSupply;
        require(amountERC > 0 && balanceNFT > 0 && amountERC <= balanceToken, 'DEMASK: INSUFFICIENT_LIQUIDITY_BURNED');
        require(amountNFT <= tokenId.length, "DEMASK: AMOUNT_NFT_WRONG");
        _burn(address(this), liquidity);
        if(liquidity == _totalSupply){
            TransferHelper.safeTransferFromERC721(NFT, address(this), to, tokenId, amountNFT);
        }else {
            uint tokenRemaining = _reserveToken.sub(amountERC);
            uint nftRemaining = _reserveNFT.sub(amountNFT);
            amountERC += (liquidity.mul(balanceNFT) - amountNFT.mul(_totalSupply)).mul(tokenRemaining)/(nftRemaining.mul(_totalSupply));
            if(amountNFT > 0 ){
                TransferHelper.safeTransferFromERC721(NFT, address(this), to, tokenId, amountNFT);
            }
        }
        if(token == WETH){
            IWETH(WETH).withdraw(amountERC);
            TransferHelper.safeTransferETH(to, amountERC);
        }else{
            TransferHelper.safeTransfer(token, to, amountERC);
        }
        balanceToken = getBalanceToken();
        balanceNFT = getBalanceNFT();
        _update(balanceToken, balanceNFT);
        if (feeOn) kLast = uint(reserveToken).mul(reserveNFT); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amountERC, amountNFT, to);
    }

    function swap(uint amountTokenOut, uint256[] memory tokenId, address to, address from, address royaltyReceiver, uint amountRoyalty) external nonReentrant {
        require( (amountTokenOut == 0 && tokenId.length > 0) || (amountTokenOut > 0 && tokenId.length == 0), 'DEMASK: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint _reserveToken, uint _reserveNFT) = getReserves();
        require(amountTokenOut < _reserveToken && tokenId.length < _reserveNFT, 'DEMASK: INSUFFICIENT_LIQUIDITY');
        uint balanceToken;
        uint balanceNFT;
         
        {
            require(to != token && to != NFT, 'DEMASK: INVALID_TO');
            if (amountTokenOut > 0) {
                uint _fee = feeManager.getTotalFee(amountTokenOut);
                if(token == WETH) IWETH(WETH).withdraw(amountTokenOut);
                (token == WETH) ? TransferHelper.safeTransferETH(to, amountTokenOut.sub(_fee)) : TransferHelper.safeTransfer(token, to, amountTokenOut.sub(_fee));
                (token == WETH && amountRoyalty > 0) ? TransferHelper.safeTransferETH(royaltyReceiver, amountRoyalty) : TransferHelper.safeTransfer(token, royaltyReceiver, amountRoyalty);
                _distribution(from, amountTokenOut);
            }
            if(tokenId.length > 0) TransferHelper.safeTransferFromERC721(NFT, address(this), to, tokenId, tokenId.length);
            balanceToken = getBalanceToken();
            balanceNFT = getBalanceNFT();

        }
        uint amounttokenIn = balanceToken > _reserveToken - amountTokenOut ? balanceToken - (_reserveToken - amountTokenOut) : 0;
        uint amountnftIn = balanceNFT > _reserveNFT - tokenId.length ? balanceNFT - (_reserveNFT - tokenId.length) : 0;
        require(amounttokenIn > 0 || amountnftIn > 0, 'DEMASK: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balancetokenAdjusted = balanceToken.mul(10000).sub(amounttokenIn.mul(25));
        uint balancenftAdjusted = balanceNFT.mul(10000).sub(amountnftIn.mul(25));
        require(balancetokenAdjusted.mul(balancenftAdjusted) >= uint(_reserveToken).mul(_reserveNFT).mul(10000**2), 'DEMASK: K');
        }
        _update(balanceToken, balanceNFT);
        emit Swap(msg.sender, amounttokenIn, amountnftIn, amountTokenOut, tokenId.length, to);
    }
    
    function _distribution(address from, uint amount) internal {
        (address[] memory feeAddress, uint[] memory feeAmount) = feeManager.getFee(amount, address(this), from);
        (token == WETH) ? TransferHelper.safeBatchTransferETH(feeAddress, feeAmount) :  TransferHelper.safeBatchTransfer(token, feeAddress, feeAmount);
    }

    function _update(uint balanceToken, uint balanceNFT) private {
        uint MAX_INT_256 = 2**256 - 1;
        require(balanceToken <= uint(MAX_INT_256) && balanceNFT <= uint(MAX_INT_256), 'DEMASK: OVERFLOW');
        reserveToken = uint(balanceToken);
        reserveNFT = uint(balanceNFT);
        emit Sync(reserveToken, reserveNFT);
    }

    function _mintFee(uint _reserve0, uint _reserve1) private returns (bool feeOn) {
        address feeTo = feeToProtocol();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply().mul(rootK.sub(rootKLast)).mul(8);
                    uint denominator = rootK.mul(17).add(rootKLast.mul(8));
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    function swapNFT(uint256[] memory tokenIdTo, address to) external nonReentrant {
        (, uint _reserveNFT) = getReserves();
        uint balanceNFT = getBalanceNFT();
        uint amountNFT = balanceNFT.sub(_reserveNFT);
        require(tokenIdTo.length == amountNFT, "DML: tokenIdTO_WRONG");
        TransferHelper.safeTransferFromERC721(NFT, address(this), to, tokenIdTo, tokenIdTo.length);
        emit SwapNFT(to, tokenIdTo, block.timestamp);
    }

}

contract FactoryERC20ERC721 is Ownable{

    address[] public allDmlTokens;
    address public feeManager;
    address public tokenList;
    address public WETH;

    mapping(address => mapping(address => address)) public dmlToken;
    
    event DmlTokenCreated(address creator,address erc, address nft, address dmlToken, uint length);
    
    constructor(address _feeManager, address _weth, address _tokenList){
        feeManager = _feeManager;
        WETH = _weth;
        tokenList = _tokenList;
    }

    modifier isCheckToken(address token) {
        require(token == WETH || ITokenList(tokenList).getState(token), "FACTORY: TOKENLIST_WRONG");
        _;
    }

    function createDMLToken(address creator,address token, address NFT) external isCheckToken(token) returns (address) {
        require(token != NFT, 'DEMASK: IDENTICAL_ADDRESSED');
        require(token != address(0) && NFT != address(0), 'DEMASK: ZERO_ADDRESS');
        require(dmlToken[token][NFT] == address(0), 'DEMASK: DML_EXISTS');
        DMLTokenERC20ERC721 _dmltoken = new DMLTokenERC20ERC721(msg.sender, token, NFT, feeManager, WETH);
        dmlToken[token][NFT] = address(_dmltoken);
        allDmlTokens.push(address(_dmltoken));
        emit DmlTokenCreated(creator, token, NFT, address(_dmltoken), allDmlTokens.length);
        return address(_dmltoken);
    }

    function getDmlToken(address token, address nft) external view returns(address){
        return dmlToken[token][nft];
    }

    function allDmlTokensLength() external view returns(uint){
        return allDmlTokens.length;
    }
}