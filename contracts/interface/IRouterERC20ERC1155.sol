interface IRouterERC20ERC1155 {
    function launchpadAddLiquidity(
        address token, 
        address nft, 
        uint256 id,
        uint amountTokenDesired,
        uint amountNFTDesired,
        uint amountTokenMin,
        address to, 
        uint deadline
    ) external returns(address);
}