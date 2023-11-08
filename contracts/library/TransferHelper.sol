library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeBatchTransfer(address token, address[] memory to, uint[] memory value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        require(to.length == value.length, "TransferHelper: LENGTH_WRONG");
        for(uint256 i = 0; i < to.length; i++){
            if(value[i] > 0 && to[i] != address(0)){
                (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to[i], value[i]));
                require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
            }
        }   
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeBatchTransferFrom(address token, address from, address[] memory to, uint[] memory value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        require(to.length == value.length, "TransferHelper: LENGTH_WRONG");
        for(uint256 i = 0; i < to.length; i++){
            if(value[i] > 0 && to[i] != address(0)){
                (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to[i], value[i]));
                require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
            }
        }
    }

    function safeTransferFromERC1155(address nft, address from, address to, uint256 id, uint value, bytes memory dataNFT) internal {
        // bytes4(keccak256(bytes('safeTransferFrom(address,address,uint256,uint256,bytes)')))
        (bool success, bytes memory data) = nft.call(abi.encodeWithSelector(0xf242432a, from, to, id, value, dataNFT));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_NFT_ERC1155_FAILED');
    }

    function safeTransferFromERC721(address nft, address from, address to, uint256[] memory tokenID, uint256 length) internal {
        // bytes4(keccak256(bytes('safeTransferFrom(address,address,uint256)')))
        require(length <= tokenID.length,"TransfeHelper: LENGTH_WRONG");
        for(uint256 i = 0; i < length; i++){
            (bool success, bytes memory data) = nft.call(abi.encodeWithSelector(0x42842e0e, from, to, tokenID[i]));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_NFT_ERC721_FAILED');
        }    
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    function safeBatchTransferETH(address[] memory to, uint[] memory value) internal {
        require(to.length == value.length, "TransferHelper: LENGTH_WRONG");
        for(uint256 i = 0; i < to.length; i++){
            if(value[i] > 0 && to[i] != address(0)){
                (bool success,) = to[i].call{value:value[i]}(new bytes(0));
                require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
            }
        }
    }
    
}