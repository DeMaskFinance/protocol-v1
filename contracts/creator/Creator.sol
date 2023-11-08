pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../erc7254/IERC7254.sol";
import "../interface/ITokenList.sol";
import "../library/TransferHelper.sol";
import "../library/SafeMath.sol";
import "./LaunchPad.sol";

contract Creator is ERC1155, Ownable, ERC1155Supply, ERC2981 {

    using SafeMath for uint;
    string private _name;
    string private _symbol;
    address public WETH;
    address public tokenList;
    address public router;
    uint public Denominator = 1000000;
    
    mapping(uint256 => string) private _uri;
    mapping(uint256 => address) private ownerOf;
    mapping(uint256 => bool) public isMinted;
    mapping(address => bool) public isLaunchPad;

    constructor(address _WETH, address _tokenList) ERC1155(""){
        _name = 'DeMask Creator';
        _symbol = 'DRC';
        WETH = _WETH;
        tokenList = _tokenList;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    modifier IsMinted(uint256 tokenId) {
        require(!isMinted[tokenId], "CREATOR: EXIST_ID");
        _;
        isMinted[tokenId] = true;
    }

    modifier IsNotMint(uint256 tokenId) {
        require(isMinted[tokenId], "CREATOR: ID_NOT_EXIST");
        _;
    }

    modifier VerifyTime(uint startTime, uint endTime) {
        require(endTime > block.timestamp && endTime > startTime);
        _;
    }
    
    modifier onlyLaunchPad(address _launchpad) {
        require(isLaunchPad[_launchpad], "CREATOR: ONLY_LAUNCHPAD");
        _;
    }

    modifier isCheckToken(address token) {
        require(token == WETH || ITokenList(tokenList).getState(token), "FACTORY: TOKENLIST_WRONG");
        _;
    }

    event LaunchpadSubmit(
        address creator,
        address launchpad,
        address tokenPayment,
        uint tokenId,
        uint initial,
        uint softcap,
        uint hardcap,
        uint percentLock,
        uint price,
        uint priceListing,
        uint startTime,
        uint endTime,
        uint durationLock,
        uint maxbuy,
        uint timeStamp,
        uint TGE,
        uint vestingTime,
        bool vestingStatus,
        bool burnType,
        bool whiteList,
        string url,
        bytes data
    );

    event Launchpad(
        address to,
        address token,
        uint tokenId,
        uint bill,
        uint amount,
        uint timeStamp
    );

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

    function addRouter(address _router) external onlyOwner(){
        require(_router != address(0));
        router = _router;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return _uri[tokenId];
    }

    function existLaunchPad(address _launchpad) public view returns (bool){
        return isLaunchPad[_launchpad];
    }

    function getRouter() public view returns(address){
        return router;
    }

    function _setURI(uint256 _tokenId, string memory _url) internal virtual{
        _uri[_tokenId] = _url;
        emit URI(_url, _tokenId);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 royaltiesFee) public {
        require(ownerOf[tokenId] == msg.sender, "CREATOR: CALLER_WRONG");
        _setTokenRoyalty(tokenId, receiver, royaltiesFee);
        emit SetTokenRoyalty(
            tokenId,
            receiver,
            royaltiesFee,
            block.timestamp
        );
    }

    function transferOwnershipNFT(uint256 tokenId, address newOwner) external {
        require(ownerOf[tokenId] == msg.sender, "CREATOR: CALLER_WRONG");
        ownerOf[tokenId] = newOwner;
        emit TransferOwnershipNFT(
            tokenId,
            msg.sender,
            newOwner,
            block.timestamp
        );
    }

    function mint(address account, uint tokenId, uint amount, uint96 royaltiesFee, bytes memory data, string memory url) public IsMinted(tokenId){       
        require(amount > 0, "CREATOR: AMOUNT_WRONG");
        _mint(account, tokenId, amount, data);
        ownerOf[tokenId] = msg.sender;
        setTokenRoyalty(tokenId, msg.sender, royaltiesFee);
        _setURI(tokenId, url);
    }

    function launchpadSubmit(LaunchPad.launchpad_data memory launchpad_information , uint96 royaltiesFee, string memory _url, bytes memory data) 
        external 
        isCheckToken(launchpad_information.tokenPayment) 
        IsMinted(launchpad_information.tokenId) 
        VerifyTime(launchpad_information.startTime, launchpad_information.endTime) {
            require(launchpad_information.price > 0 && launchpad_information.priceListing > 0 , "PRICE_WRONG");
            require(launchpad_information.maxbuy >= 1, "CREATOR: MAXBUY_WRONG");
            require(launchpad_information.hardcap >= launchpad_information.softcap, "CREATOR: CAP_WRONG");
            require(launchpad_information.price * launchpad_information.softcap * launchpad_information.percentLock / ( launchpad_information.priceListing * Denominator) > 0, "CREATOR: SOFTCAP_WRONG");
            if(launchpad_information.vestingStatus) require(launchpad_information.vestingTime > 0, "CREATOR: VESTINGTIME_WRONG");
            require(router != address(0), "CREATOR: WAITING_ADD_ROUTER");
            require(launchpad_information.percentLock > 0 && launchpad_information.percentLock <= Denominator, "CREATOR: EXCEED_PERCENT");
            uint maxNFTAddPool =  launchpad_information.price * launchpad_information.hardcap * launchpad_information.percentLock / ( launchpad_information.priceListing * Denominator);
            uint totalSupply_id = launchpad_information.initial + maxNFTAddPool +  launchpad_information.hardcap;
            LaunchPad launchPad = new LaunchPad(launchpad_information, address(this), WETH, router, totalSupply_id);
            mint(address(launchPad), launchpad_information.tokenId, totalSupply_id, royaltiesFee, data, _url);
            isLaunchPad[address(launchPad)] = true;
            emit LaunchpadSubmit(
                msg.sender, 
                address(launchPad),
                launchpad_information.tokenPayment, 
                launchpad_information.tokenId, 
                launchpad_information.initial, 
                launchpad_information.softcap, 
                launchpad_information.hardcap, 
                launchpad_information.percentLock, 
                launchpad_information.price, 
                launchpad_information.priceListing,
                launchpad_information.startTime,
                launchpad_information.endTime,
                launchpad_information.durationLock, 
                launchpad_information.maxbuy,
                block.timestamp,
                launchpad_information.TGE,
                launchpad_information.vestingTime,
                launchpad_information.vestingStatus,
                launchpad_information.burnType,
                launchpad_information.whiteList,
                _url,
                data
            );
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
