interface IFactoryERC20ERC721 {
    function getDmlToken(address token, address nft) external view returns(address);
    function createDMLToken(address creator, address token, address nft) external returns (address dmlToken);
    function swapNFT(uint256[] memory tokenIDTo, address to) external;
}