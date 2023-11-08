interface IFactoryERC20ERC1155 {
    function getDmlToken(address token, address nft, uint256 id) external view returns(address);
    function createDMLToken(address creator, address token, address nft, uint256 id) external returns (address dmlToken);
}