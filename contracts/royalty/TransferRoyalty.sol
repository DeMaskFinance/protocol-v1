pragma solidity ^0.8.9;

import "../interface/IRoyaltyEngineV1.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TransferRoyalty {

    receive() external payable {}
    
    function transferRoyalty(address _royalty, address token, address nft, uint256 tokenId, uint256 value) external {
        (address payable[] memory recipients, uint256[] memory amounts) = IRoyaltyEngineV1(_royalty).getRoyaltyView(nft, tokenId, value);
        for(uint256 i = 0; i < recipients.length; i++){
            if(amounts[i] > 0 && recipients[i] != address(0)){
                (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, msg.sender, recipients[i], amounts[i]));
                require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
            }
        }
    }

    function transferRoyaltyETH(address _royalty, address nft, uint256 tokenId, uint256 value) external {
        (address payable[] memory recipients, uint256[] memory amounts) = IRoyaltyEngineV1(_royalty).getRoyaltyView(nft, tokenId, value);
        for(uint256 i = 0; i < recipients.length; i++){
            if(amounts[i] > 0 && recipients[i] != address(0)){
                (bool success,) = recipients[i].call{value:amounts[i]}(new bytes(0));
                require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
            }
        }
    }
}