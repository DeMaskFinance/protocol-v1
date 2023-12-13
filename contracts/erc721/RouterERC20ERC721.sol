pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../interface/IDMLTokenERC20ERC721.sol";
import "../interface/IFactoryERC20ERC721.sol";
import "../interface/IWETH.sol";
import "../interface/IFeeManager.sol";
import "../library/SafeMath.sol";
import "../library/TransferHelper.sol";
import "../interface/IRoyaltyEngineV1.sol";

contract RouterERC20ERC721 is ERC721Holder, Ownable {

    using SafeMath for uint;
    address public WETH;
    uint[] ARRAY_NULL;
    IFactoryERC20ERC721 public factoryERC20ERC721;
    IFeeManager public feeManager; 
    IRoyaltyEngineV1 public royaltyEngine;
    uint public Denominator = 1000000;

    constructor(address _feeManager, address _factoryERC20ERC721, address _WETH, address _royaltyEngine){
        factoryERC20ERC721 = IFactoryERC20ERC721(_factoryERC20ERC721);
        feeManager = IFeeManager(_feeManager);
        WETH = _WETH;
        royaltyEngine = IRoyaltyEngineV1(_royaltyEngine);
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'DeMaskRouter: EXPIRED');
        _;
    }

    event MakeTransaction( 
        string action,
        address to,
        address sender,
        address dml,
        uint amounttoken,
        uint amountNFT,
        uint[] tokenId,
        uint reserveToken,
        uint reserveNFT,
        uint blockTime
    );

    event MakeLiquidity(
        string action,
        address to,
        address sender,
        address dml,
        uint amounttoken,
        uint amountNFT,
        uint[] tokenId,
        uint liquidity,
        uint reserveToken,
        uint reserveNFT,
        uint blockTime
    );

    event Swap(
        address from,
        address dml,
        uint[] tokenIdFrom,
        uint[] tokenIdTo,
        address to,
        uint blockTime
    );

    function addERC20ERC721(
        address token, 
        address NFT, 
        uint256[] memory tokenId,
        uint amountTokenDesired,
        uint amountTokenMin,
        address to, 
        uint deadline
        ) external payable ensure(deadline) returns(uint amountToken, uint amountNFT, uint liquidity) {
        (amountToken, amountNFT) = _addERC20ERC721(token, NFT, amountTokenDesired, tokenId.length, amountTokenMin);
        address _token = factoryERC20ERC721.getDmlToken(token, NFT);
        TransferHelper.safeTransferFromERC721(NFT, msg.sender, _token, tokenId, amountNFT);
        if(token == WETH){
            IWETH(WETH).deposit{value: amountToken}();
            assert(IWETH(WETH).transfer(_token, amountToken));
            if (msg.value > amountToken) TransferHelper.safeTransferETH(msg.sender, msg.value.sub(amountToken));
        }else{
            TransferHelper.safeTransferFrom(token, msg.sender, _token, amountToken);
        }
        
        liquidity = IDMLTokenERC20ERC721(_token).mint(to);
        (uint _reserveToken, uint _reserveNFT, ) = getReservesERC20ERC721(token, NFT);
        emit MakeLiquidity(
            'Add',
            to,
            msg.sender,
            _token,
            amountToken,
            amountNFT,
            tokenId,
            liquidity,
            _reserveToken,
            _reserveNFT,
            block.timestamp
        );
    }

    function _addERC20ERC721(
        address token,
        address NFT,
        uint amountTokenDesired,
        uint amountNFTDesired,
        uint amountTokenMin
    ) internal virtual returns (uint amountToken, uint amountNFT) {
        if(factoryERC20ERC721.getDmlToken(token, NFT) == address(0)){
           factoryERC20ERC721.createDMLToken(msg.sender, token, NFT);
        }
        
        (uint _reserveToken, uint _reserveNFT, ) = getReservesERC20ERC721(token, NFT);
        if(_reserveToken == 0 && _reserveNFT == 0){
            (amountToken, amountNFT) = (amountTokenDesired, amountNFTDesired);
        } else {
            uint amountTokenOptimal = amountNFTDesired * _reserveToken / _reserveNFT;
            require(amountTokenOptimal <= amountTokenDesired && amountTokenOptimal >= amountTokenMin, 'DeMaskRouter: INSUFFICIENT_ERC_AMOUNT');
            (amountToken, amountNFT) = (amountTokenOptimal, amountNFTDesired);
        }

    }

    function getReservesERC20ERC721(
        address token,
        address NFT
    ) internal view returns(uint _reserveToken, uint _reserveNFT, address _token){
        _token = factoryERC20ERC721.getDmlToken(token, NFT);
        ( _reserveToken, _reserveNFT) = IDMLTokenERC20ERC721(_token).getReserves();
    }

    function removeERC20ERC721(
        address token,
        address NFT,
        uint256[] memory tokenId,
        uint liquidity,
        uint amountTokenMin,
        uint amountNFTMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountToken, uint amountNFT){
        address _token = factoryERC20ERC721.getDmlToken(token, NFT);
        TransferHelper.safeTransferFrom(_token, msg.sender, _token, liquidity);
        (amountToken, amountNFT) = IDMLTokenERC20ERC721(_token).burn(to, tokenId);
        require(amountToken >= amountTokenMin, 'DeMaskRouter: INSUFFICIENT_ERC_AMOUNT');
        require(amountNFT >= amountNFTMin, 'DeMaskRouter: INSUFFICIENT_NFT_AMOUNT');
        (uint _reserveToken, uint _reserveNFT, ) = getReservesERC20ERC721(token, NFT);
        emit MakeLiquidity(
            'Remove',
            to,
            msg.sender,
            _token,
            amountToken,
            amountNFT,
            tokenId,
            liquidity,
            _reserveToken,
            _reserveNFT,
            block.timestamp
        );
    }
    
    function getAmountBuy(
        address token,
        address NFT,
        uint256[] memory tokenId
    ) public view returns (uint amountAFee, uint feeBuy){
        (uint _reserveToken, uint _reserveNFT, ) = getReservesERC20ERC721(token, NFT);
        uint amountNFT = tokenId.length;
        require(amountNFT > 0, 'DeMaskRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        require(_reserveToken > 0 && _reserveNFT > 0, 'DeMaskRouter: INSUFFICIENT_LIQUIDITY');
        uint numerator = _reserveToken.mul(amountNFT).mul(10000);
        uint denominator = _reserveNFT.sub(amountNFT).mul(9975);
        uint amountIn = (numerator / denominator).add(1);
        feeBuy = feeManager.getTotalFee(amountIn);
        amountAFee = amountIn.add(feeBuy);
    }

    function getAmountSell(
        address token,
        address NFT,
        uint256[] memory tokenId
    ) public view returns (uint amountAFee, uint feeSell){
        (uint _reservetoken, uint _reserveNFT, ) = getReservesERC20ERC721(token, NFT);
        uint amountNFT = tokenId.length;
        require(amountNFT > 0, 'DeMaskRouter: INSUFFICIENT_INPUT_AMOUNT');
        require(_reservetoken > 0 && _reserveNFT > 0, 'DeMaskRouter: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountNFT.mul(9975);
        uint numerator = amountInWithFee.mul(_reservetoken);
        uint denominator = _reserveNFT.mul(10000).add(amountInWithFee);
        uint amountOut = numerator / denominator;
        feeSell = feeManager.getTotalFee(amountOut);
        amountAFee = amountOut.sub(feeSell);
    }

    function getRoyalty(
        address NFT,
        uint256 tokenId,
        uint amount
    ) public view returns (bool status, address receiver) {
            (address payable[] memory royaltyReceiver, ) = royaltyEngine.getRoyaltyView(NFT, tokenId, amount);
            if(royaltyReceiver.length > 0){
                status = true;
                receiver = royaltyReceiver[0];
            }    
    }

    function buyERC20ERC721(
        address token,
        address NFT,
        uint256[] memory tokenId,
        uint amountInMax,
        uint royaltyFee,
        address to,
        uint deadline
    ) external payable ensure(deadline) returns(uint) {
        uint amountRoyalty = 0;
        (,, address _token) = getReservesERC20ERC721(token, NFT);
        (uint amount, uint feeBuy) = getAmountBuy(token, NFT, tokenId);
        require(royaltyFee <= Denominator && royaltyFee >= 5000, "DeMaskRouter: ROYALTY_FEE_WRONG");
        (bool status, address royaltyReceiver) = getRoyalty(NFT, tokenId[0], amount);
        if(status){
            amountRoyalty = amount * royaltyFee / Denominator;
        }
        require(amount + amountRoyalty <= amountInMax, 'DeMaskRouter: EXCESSIVE_INPUT_AMOUNT');
        if(token == WETH){
            require(amountInMax == msg.value, "ROUTER: MSG_VALUE_WRONG");
            IWETH(WETH).deposit{value: amount.sub(feeBuy)}();
            TransferHelper.safeTransfer(WETH, _token, amount.sub(feeBuy));
            if (msg.value > (amount + amountRoyalty)) TransferHelper.safeTransferETH(msg.sender, msg.value.sub(amount).sub(amountRoyalty));
            if(amountRoyalty > 0) TransferHelper.safeTransferETH(royaltyReceiver, amountRoyalty);
        }else {
            TransferHelper.safeTransferFrom(token, msg.sender, _token, amount.sub(feeBuy));
            if(amountRoyalty > 0) TransferHelper.safeTransferFrom(token, msg.sender, royaltyReceiver, amountRoyalty);
        }
        _feeDistribution(_token, token, amount.sub(feeBuy));
        _swapAndUpdateReward(token, 0, tokenId, to, msg.sender, amount.sub(feeBuy) , _token, royaltyReceiver, amountRoyalty);
        (uint _reserveToken, uint _reserveNFT, ) = getReservesERC20ERC721(token, NFT);
        emit MakeTransaction(
            'Buy',
            to, 
            msg.sender, 
            _token, 
            amount, 
            tokenId.length, 
            tokenId,
            _reserveToken,
            _reserveNFT,
             block.timestamp
        );
        return amount;
    }

    function sellERC20ERC721(
        address token,
        address NFT,
        uint256[] memory tokenId,
        uint amountOutMin,
        uint royaltyFee,
        address to,
        uint deadline
    ) external ensure(deadline) returns(uint)  {
        uint amountRoyalty = 0;
        (,, address _token) = getReservesERC20ERC721(token, NFT);
        (uint amount, uint feeSell) = getAmountSell(token, NFT, tokenId);
        require(royaltyFee <= Denominator && royaltyFee >= 5000, "DeMaskRouter: ROYALTY_FEE_WRONG");
        (bool status, address royaltyReceiver) = getRoyalty(NFT, tokenId[0], amount);
        if(status){
            amountRoyalty = amount * royaltyFee / Denominator;
        }
        require(amount - amountRoyalty >= amountOutMin, 'DeMaskRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFromERC721(NFT, msg.sender, _token, tokenId, tokenId.length);
        _swapAndUpdateReward(token, amount.add(feeSell), ARRAY_NULL, to, msg.sender, amount.add(feeSell), _token, royaltyReceiver, amountRoyalty);
        (uint _reserveToken, uint _reserveNFT, ) = getReservesERC20ERC721(token, NFT);
        emit MakeTransaction(
            'Sell',
            to, 
            msg.sender, 
            _token, 
            amount, 
            tokenId.length,
            tokenId, 
            _reserveToken,
            _reserveNFT, 
            block.timestamp
        );
        return amount;
    }

    function swap(address NFT, address token, uint256[] memory tokenIdFrom, uint256[] memory tokenIdTo, address to, uint deadline) external payable ensure(deadline) {
        require(tokenIdFrom.length == tokenIdTo.length, "CREATOR: TOKEN_LENGTH_WRONG");
        (,, address _token) = getReservesERC20ERC721(token, NFT);
        (uint amount, uint feeBuy) = getAmountBuy(token, NFT, tokenIdFrom);
        if(token == WETH){
            require(feeBuy <= msg.value, "ROUTER: MSG_VALUE_WRONG");
            IWETH(WETH).deposit{value: feeBuy }();
            if (msg.value > feeBuy) TransferHelper.safeTransferETH(msg.sender, msg.value.sub(feeBuy));
        }
        _feeDistribution(_token, token, amount.sub(feeBuy));
        address[] memory tokenReward = new address[](1);
        uint[] memory amountReward = new uint[](1);
        tokenReward[0] = token;
        amountReward[0] = feeManager.getFeeLiquidity(amount.sub(feeBuy));
        IDMLTokenERC20ERC721(_token).updateReward(tokenReward, amountReward);
        TransferHelper.safeTransferFromERC721(NFT, msg.sender, _token, tokenIdFrom, tokenIdFrom.length);
        factoryERC20ERC721.swapNFT(tokenIdTo, to);
        emit Swap(msg.sender, _token, tokenIdFrom, tokenIdTo, to, block.timestamp);
    }

    function _swapAndUpdateReward(address _tokenReward, uint amountTokenOut, uint256[] memory tokenId, address to, address from, uint _amount, address _token, address royaltyReceiver, uint amountRoyalty) internal {
        IDMLTokenERC20ERC721(_token).swap(amountTokenOut, tokenId, to, from, royaltyReceiver, amountRoyalty);
        address[] memory tokenReward = new address[](1);
        uint[] memory amountReward = new uint[](1);
        tokenReward[0] = _tokenReward;
        amountReward[0] = feeManager.getFeeLiquidity(_amount);
        IDMLTokenERC20ERC721(_token).updateReward(tokenReward, amountReward);
    }

    function _feeDistribution(address _token, address token, uint amount) internal {
        (address[] memory feeAddress, uint[] memory feeAmount) = feeManager.getFee(amount, _token, msg.sender);
        (token == WETH) ? TransferHelper.safeBatchTransferETH(feeAddress, feeAmount) :  TransferHelper.safeBatchTransferFrom(token, msg.sender, feeAddress, feeAmount);
    }
}