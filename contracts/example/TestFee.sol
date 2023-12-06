pragma solidity ^0.8.9; 
import "../interface/IFeeManager.sol";
import "../library/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
contract TestFee {
    IFeeManager public feemanager;
    address public receiver;
    constructor(address _feemanager, address _receiver){
        feemanager = IFeeManager(_feemanager);
        receiver = _receiver;
    }

    function sendFee(uint amount, address token, address dml, address nft, uint256 id) external {
        TransferHelper.safeTransferFrom(token, msg.sender, receiver, amount);
        address[] memory feeAddress =  new address[](4);
        uint[] memory feeAmount = new uint[](4);
        (feeAddress, feeAmount) = feemanager.getFee(amount, dml, msg.sender);
        TransferHelper.safeBatchTransferFrom(token, msg.sender, feeAddress, feeAmount);
    }

    function viewFee(uint amount, address token, address dml, address nft, uint256 id) external {
        TransferHelper.safeTransferFrom(token, msg.sender, receiver, amount);
        address[] memory feeAddress =  new address[](4);
        uint[] memory feeAmount = new uint[](4);
        (feeAddress, feeAmount) = feemanager.getFee(amount, dml, msg.sender);
    }
    
    function feem(uint amount) public view returns(uint[] memory, uint[] memory){
        uint[] memory fee = new uint[](2);
        fee[0] = 1;
        fee[1] = 2;
        uint[] memory f = new uint[](2);
        f[0] = 32;
        f[1] =3;
        return (fee,f);
    }

    function readERC20(address token, address user) public view returns(uint256){
         (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, user)
        );
        require(success);
        return abi.decode(data, (uint256));
    }

    function readERC721(address nft, address user) public view returns(uint256){
        (bool success, bytes memory data) = nft.staticcall(
            abi.encodeWithSelector(IERC721.balanceOf.selector, user)
        );
        require(success);
        return abi.decode(data, (uint256));
    }

    function readERC1155(address nft, uint256 id, address user) public view returns(uint256){
        (bool success, bytes memory data) = nft.staticcall(
            abi.encodeWithSelector(IERC1155.balanceOf.selector, user, id)
        );
        require(success);
        return abi.decode(data, (uint256));
    }

    uint a;
    uint b;

    function nonUnchecked(uint _a) external {
        a = _a;
    }

    function useUnchecked(uint _b) external {
        unchecked{
            b = _b;
        }
    }
    
}