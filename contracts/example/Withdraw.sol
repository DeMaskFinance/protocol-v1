import "../interface/IWETH.sol";
contract Withdraw {
    receive() external payable {
        // assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }
    function withdraw(address weth, uint amount) external {
        IWETH(weth).withdraw(amount);
    }

     function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    function withdraw1(address weth, uint amount) external {
        IWETH(weth).withdraw(amount);
        safeTransferETH(msg.sender, amount);
    }
}