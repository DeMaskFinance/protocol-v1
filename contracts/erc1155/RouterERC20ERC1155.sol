pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IDMLTokenERC20ERC1155.sol";
import "../interface/IFactoryERC20ERC1155.sol";
import "../interface/IWETH.sol";
import "../interface/IFeeManager.sol";
import "../library/SafeMath.sol";
import "../library/TransferHelper.sol";
import "../interface/IRoyaltyEngineV1.sol";

contract RouterERC20ERC1155 is ERC1155Holder, Ownable {

    using SafeMath for uint;
    address public WETH;
    IFactoryERC20ERC1155 public factoryERC20ERC1155;
    IFeeManager public feeManager; 
    IRoyaltyEngineV1 public royaltyEngine;
    uint public Denominator = 1000000;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'DeMaskRouter: EXPIRED');
        _;
    }

    constructor(address _feeManager, address _factoryERC20ERC1155, address _WETH, address _royaltyEngine){
        factoryERC20ERC1155 = IFactoryERC20ERC1155(_factoryERC20ERC1155);
        feeManager = IFeeManager(_feeManager);
        WETH = _WETH;
        royaltyEngine = IRoyaltyEngineV1(_royaltyEngine);
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    event MakeTransaction( 
        string action,
        address to,
        address sender,
        address dml,
        uint amountToken,
        uint amountNFT,
        uint reserveToken,
        uint reserveNFT,
        uint blockTime
    );

    event MakeLiquidity(
        string action,
        address to,
        address sender,
        address dml,
        uint amountToken,
        uint amountNFT,
        uint liquidity,
        uint reserveToken,
        uint reserveNFT,
        uint blockTime
    );
    
    function addERC20ERC1155(
        address token, 
        address NFT, 
        uint256 tokenId,
        uint amountTokenDesired,
        uint amountNFTDesired,
        uint amountTokenMin,
        address to, 
        uint deadline
        ) external payable ensure(deadline) returns(uint amountToken, uint amountNFT, uint liquidity) {
        (amountToken, amountNFT) = _addERC20ERC1155(token, NFT, tokenId, amountTokenDesired, amountNFTDesired, amountTokenMin);
        address _token = factoryERC20ERC1155.getDmlToken(token, NFT, tokenId);
        TransferHelper.safeTransferFromERC1155(NFT, msg.sender, _token, tokenId, amountNFT, bytes(''));
        if(token == WETH){
            IWETH(WETH).deposit{value: amountToken}();
            assert(IWETH(WETH).transfer(_token, amountToken));
            if (msg.value > amountToken) TransferHelper.safeTransferETH(msg.sender, msg.value.sub(amountToken));
        }else{
            TransferHelper.safeTransferFrom(token, msg.sender, _token, amountToken);
        }
        liquidity = IDMLTokenERC20ERC1155(_token).mint(to);
        (uint _reserveToken, uint _reserveNFT, ) = getReservesERC20ERC1155(token, NFT, tokenId);
        emit MakeLiquidity(
            'Add',
            to,
            msg.sender,
            _token,
            amountToken,
            amountNFT,
            liquidity,
            _reserveToken,
            _reserveNFT,
            block.timestamp
        );
    }

    function _addERC20ERC1155(
        address token,
        address NFT,
        uint256 tokenId,
        uint amountTokenDesired,
        uint amountNFTDesired,
        uint amountTokenMin
    ) internal virtual returns (uint amountToken, uint amountNFT) {
        if(factoryERC20ERC1155.getDmlToken(token, NFT, tokenId) == address(0)){
           factoryERC20ERC1155.createDMLToken(msg.sender, token, NFT, tokenId);
        }
        
        (uint _reservetoken, uint _reservenft, ) = getReservesERC20ERC1155(token, NFT, tokenId);
        if(_reservetoken == 0 && _reservenft == 0){
            (amountToken, amountNFT) = (amountTokenDesired, amountNFTDesired);
        } else {
            uint amountTokenOptimal = amountNFTDesired * _reservetoken / _reservenft;
            require(amountTokenOptimal <= amountTokenDesired && amountTokenOptimal >= amountTokenMin, 'DeMaskRouter: INSUFFICIENT_ERC_AMOUNT');
            (amountToken, amountNFT) = (amountTokenOptimal, amountNFTDesired);
        }

    }

    function getReservesERC20ERC1155(
        address token,
        address NFT,
        uint256 tokenId
    ) internal view returns(uint _reserveToken, uint _reserveNFT, address _token){
        _token = factoryERC20ERC1155.getDmlToken(token, NFT, tokenId);
        ( _reserveToken, _reserveNFT) = IDMLTokenERC20ERC1155(_token).getReserves();
    }

    function removeERC20ERC1155(
        address token,
        address NFT,
        uint256 tokenId,
        uint liquidity,
        uint amountTokenMin,
        uint amountNFTMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountToken, uint amountNFT){
        address _token = factoryERC20ERC1155.getDmlToken(token, NFT, tokenId);
        TransferHelper.safeTransferFrom(_token, msg.sender, _token, liquidity);
        (amountToken, amountNFT) = IDMLTokenERC20ERC1155(_token).burn(to);
        require(amountToken >= amountTokenMin, 'DeMaskRouter: INSUFFICIENT_ERC_AMOUNT');
        require(amountNFT >= amountNFTMin, 'DeMaskRouter: INSUFFICIENT_NFT_AMOUNT');
        (uint _reservetoken, uint _reservenft, ) = getReservesERC20ERC1155(token, NFT, tokenId);
        emit MakeLiquidity(
            'Remove',
            to,
            msg.sender,
            _token,
            amountToken,
            amountNFT,
            liquidity,
            _reservetoken,
            _reservenft,
            block.timestamp
        );
    }

    function getAmountBuy(
        address token,
        address NFT,
        uint256 tokenId,
        uint amountNFT
    ) public view returns (uint amountAFee, uint feeBuy){
        (uint _reserveToken, uint _reserveNFT, ) = getReservesERC20ERC1155(token, NFT, tokenId);
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
        uint256 tokenId,
        uint amountNFT
    ) public view returns (uint amountAFee, uint feeSell){
        (uint _reserveToken, uint _reserveNFT, ) = getReservesERC20ERC1155(token, NFT, tokenId);
        require(amountNFT > 0, 'DeMaskRouter: INSUFFICIENT_INPUT_AMOUNT');
        require(_reserveToken > 0 && _reserveNFT > 0, 'DeMaskRouter: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountNFT.mul(9975);
        uint numerator = amountInWithFee.mul(_reserveToken);
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

    function buyERC20ERC1155(
        address token,
        address NFT,
        uint256 tokenId,
        uint amountNFT,
        uint amountInMax,
        uint royaltyFee,
        address to,
        uint deadline
    ) external payable ensure(deadline) returns(uint) {
        uint amountRoyalty = 0;
        (,, address _token) = getReservesERC20ERC1155(token, NFT, tokenId);
        (uint amount, uint feeBuy) = getAmountBuy(token, NFT, tokenId, amountNFT);
        require(royaltyFee <= Denominator && royaltyFee >= 5000, "DeMaskRouter: ROYALTY_FEE_WRONG");
        (bool status, address royaltyReceiver) = getRoyalty(NFT, tokenId, amount);
        if(status){
            amountRoyalty = amount * royaltyFee / Denominator;
        }
        require(amount + amountRoyalty <= amountInMax, 'DeMaskRouter: EXCESSIVE_INPUT_AMOUNT');
        if(token == WETH){
            require(amountInMax == msg.value, "ROUTER: MSG_VALUE_WRONG");
            IWETH(WETH).deposit{value: amount.sub(feeBuy) }();
            TransferHelper.safeTransfer(WETH, _token, amount.sub(feeBuy));
            if (msg.value > (amount + amountRoyalty)) TransferHelper.safeTransferETH(msg.sender, msg.value.sub(amount).sub(amountRoyalty));
            if(amountRoyalty > 0) TransferHelper.safeTransferETH(royaltyReceiver, amountRoyalty);
        }else{
            TransferHelper.safeTransferFrom(token, msg.sender, _token, amount.sub(feeBuy));
            if(amountRoyalty > 0) TransferHelper.safeTransferFrom(token, msg.sender, royaltyReceiver, amountRoyalty);
        }
        _feeDistribution(_token, token, amount.sub(feeBuy));
        _swapAndUpdateReward(token, 0, amountNFT, to, msg.sender, amount.sub(feeBuy), _token, royaltyReceiver, amountRoyalty);
        (uint _reserveToken, uint _reserveNFT, ) = getReservesERC20ERC1155(token, NFT, tokenId);
        emit MakeTransaction(
            'Buy',
            to, 
            msg.sender, 
            _token, 
            amount, 
            amountNFT, 
            _reserveToken,
            _reserveNFT,
             block.timestamp
        );
        return amount;
    }

    function sellERC20ERC1155(
        address token,
        address NFT,
        uint256 tokenId,
        uint amountNFT,
        uint amountOutMin,
        uint royaltyFee,
        address to,
        uint deadline
    ) external ensure(deadline) returns(uint) {
        uint amountRoyalty = 0;
        (,, address _token) = getReservesERC20ERC1155(token, NFT, tokenId);
        (uint amount, uint feeSell) = getAmountSell(token, NFT, tokenId, amountNFT);
        require(royaltyFee <= Denominator && royaltyFee >= 5000, "DeMaskRouter: ROYALTY_FEE_WRONG");
        (bool status, address royaltyReceiver) = getRoyalty(NFT, tokenId, amount);
        if(status){
            amountRoyalty = amount * royaltyFee / Denominator;
        }
        require(amount - amountRoyalty >= amountOutMin, 'DeMaskRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFromERC1155(NFT, msg.sender, _token, tokenId, amountNFT, bytes(''));
        _swapAndUpdateReward(token, amount.add(feeSell), 0, to, msg.sender, amount.add(feeSell), _token, royaltyReceiver, amountRoyalty);
        (uint _reserveToken, uint _reserveNFT, ) = getReservesERC20ERC1155(token, NFT, tokenId);
        emit MakeTransaction(
            'Sell',
            to, 
            msg.sender, 
            _token, 
            amount, 
            amountNFT, 
            _reserveToken,
            _reserveNFT, 
            block.timestamp
        );
        return amount;
    }

    function _swapAndUpdateReward(address _tokenReward, uint amounttokenOut, uint amountnftOut, address to, address from, uint _amount, address _token, address royaltyReceiver, uint amountRoyalty) internal {
        IDMLTokenERC20ERC1155(_token).swap(amounttokenOut, amountnftOut, to, from, royaltyReceiver, amountRoyalty);
        address[] memory tokenReward = new address[](1);
        uint[] memory amountReward = new uint[](1);
        tokenReward[0] = _tokenReward;
        amountReward[0] = feeManager.getFeeLiquidity(_amount);
        IDMLTokenERC20ERC1155(_token).updateReward(tokenReward, amountReward);
    }

    function _feeDistribution(address _token, address token, uint amount) internal {
        (address[] memory feeAddress, uint[] memory feeAmount) = feeManager.getFee(amount, _token, msg.sender);
        (token == WETH) ? TransferHelper.safeBatchTransferETH(feeAddress, feeAmount) :  TransferHelper.safeBatchTransferFrom(token, msg.sender, feeAddress, feeAmount);
    }
}