pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../library/TransferHelper.sol";
import "../library/SafeMath.sol";

contract Mint is ERC1155, Ownable, ERC1155Supply, ERC2981 {

    using SafeMath for uint;
    string private _name;
    string private _symbol;
    
    mapping(uint256 => string) private _uri;
    mapping(uint256 => address) private ownerOf;
    mapping(uint256 => bool) public isMinted;

    constructor() ERC1155(""){
        _name = 'DeMask NFT';
        _symbol = 'DRN';
    }

    modifier IsMinted(uint256 tokenId) {
        require(!isMinted[tokenId], "MINT: EXIST_ID");
        _;
        isMinted[tokenId] = true;
    }

    modifier IsNotMint(uint256 tokenId) {
        require(isMinted[tokenId], "MINT: ID_NOT_EXIST");
        _;
    }

    event SetTokenRoyalty(
        uint256 tokenId, 
        address receiver, 
        uint96 fee,
        uint256 blockTime
    );

    event TransferOwnershipNFT(
        uint256 tokenId,
        address oldOwner,
        address newOwner,
        uint256 blockTime
    );

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return _uri[tokenId];
    }

    function _setURI(uint256 _tokenId, string memory _url) internal virtual{
        _uri[_tokenId] = _url;
        emit URI(_url, _tokenId);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 royaltiesFee) public {
        require(ownerOf[tokenId] == msg.sender, "MINT: CALLER_WRONG");
        _setTokenRoyalty(tokenId, receiver, royaltiesFee);
        emit SetTokenRoyalty(
            tokenId,
            receiver,
            royaltiesFee,
            block.timestamp
        );
    }

    function transferOwnershipNFT(uint256 tokenId, address newOwner) external {
        require(ownerOf[tokenId] == msg.sender, "MINT: CALLER_WRONG");
        ownerOf[tokenId] = newOwner;
        emit TransferOwnershipNFT(
            tokenId,
            msg.sender,
            newOwner,
            block.timestamp
        );
    }

    function mint(address account, uint tokenId, uint amount, uint96 royaltiesFee, bytes memory data, string memory url) public IsMinted(tokenId){       
        require(amount > 0, "MINT: AMOUNT_WRONG");
        _mint(account, tokenId, amount, data);
        ownerOf[tokenId] = msg.sender;
        setTokenRoyalty(tokenId, msg.sender, royaltiesFee);
        _setURI(tokenId, url);
    }

    function burn(uint tokenId, uint amount) external {
        _burn(msg.sender, tokenId, amount);
    }
    
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
