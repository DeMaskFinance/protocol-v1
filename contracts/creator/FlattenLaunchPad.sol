// Sources flattened with hardhat v2.19.0 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/introspection/IERC165.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC1155/IERC1155.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/utils/introspection/ERC165.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// File @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}


// File @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


// File contracts/interface/IWETH.sol

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// File contracts/library/TransferHelper.sol

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


// File contracts/creator/LaunchPad.sol

pragma solidity ^0.8.9;





contract LaunchPad is ERC1155Holder {

    // buy, claim, leave, withdraw
    uint256 public tokenId;
    uint public price;
    uint public softcap;
    uint public hardcap;
    uint public startTime;
    uint public endTime;
    uint public tge;
    uint public vesting;
    uint public purchaseLimit;
    uint public totalSoldout;
    uint public Denominator = 1000000;
    address public WETH;
    address public NFT;
    address public tokenPayment;
    address public creator;
    bool public isWithdrawn = false;
    bool public softcapmet;
    
    mapping(address => uint) public balanceOf;
    mapping(address => uint) public tokenReleased;

    constructor(
        address _weth,
        address _tokenPayment, 
        address _nft,
        uint256 _tokenId, 
        uint _price,
        uint _softcap, 
        uint _hardcap, 
        uint _startTime,
        uint _endTime,
        uint _tge, 
        uint _vesting, 
        uint _purchaseLimit
    ) {
        WETH = _weth;
        tokenPayment = _tokenPayment;
        NFT = _nft;
        tokenId = _tokenId;
        price = _price;
        softcap = _softcap;
        hardcap = _hardcap;
        tge = _tge;
        vesting = _vesting;
        purchaseLimit = _purchaseLimit;
        startTime = _startTime;
        endTime = _endTime;
        creator = msg.sender;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    modifier onlyCreator(){
        require(msg.sender == creator, "LAUNCHPAD: CREATOR_WRONG");
        _;
    }

    modifier verifyTransactionAmount(uint _amount){
        require( (totalSoldout + _amount) * price <= hardcap, "LAUNCHPAD: AMOUNT_WRONG");
        require(balanceOf[msg.sender] + _amount <= purchaseLimit, "LAUNCHPAD: PURCHASE_LIMIT_WRONG");
        if( (totalSoldout + _amount) * price >= softcap) softcapmet = true;
        _;
    }

    modifier verifyTimeClaimForUser(){
        require(block.timestamp > endTime, "LAUNCHPAD: WAITING_FOR_LAUNCHPAD_TO_BE_END");
        _;
    }

    modifier verifyTimeBuyForUser(){
        require(block.timestamp > startTime && block.timestamp <= endTime, "LAUNCHPAD: WAITING_FOR_LAUNCHPAD_TO_BE_OPENED");
        _;
    }

    event Buy( address user, uint amount, uint totalSold, uint blockTime);

    event Leave( address user, uint amount, uint totalSold, uint blockTime);

    event Released( address user, uint amount, uint blockTime);

    event Withdraw(address creator, uint amount, uint blockTime);

    function buy(uint _amount) external payable verifyTimeBuyForUser() verifyTransactionAmount(_amount){
        uint totalOrderValue = price * _amount;
        if(tokenPayment == WETH){
            require(msg.value >= totalOrderValue, "LAUNCHPAD: BUY_WRONG");
            if (msg.value > totalOrderValue) TransferHelper.safeTransferETH(msg.sender, msg.value - totalOrderValue);

        }else{
           TransferHelper.safeTransferFrom(tokenPayment, msg.sender, address(this), totalOrderValue); 
        }
        balanceOf[msg.sender] += _amount;
        totalSoldout += _amount;
        emit Buy(msg.sender, _amount, totalSoldout, block.timestamp);
    }

    function leave(uint amount) external {
        require(!softcapmet, "LAUNCHPAD: SOFTCAP_WRONG");
        require(balanceOf[msg.sender] >= amount && amount > 0, "LAUNCHPAD: BALANCEOF_WRONG");
        balanceOf[msg.sender] -= amount;
        totalSoldout -= amount;
        if(tokenPayment == WETH){
            TransferHelper.safeTransferETH(msg.sender, price * amount);
        }else {
            TransferHelper.safeTransfer(tokenPayment, msg.sender, price * amount);
        }     
        emit Leave(msg.sender, amount, totalSoldout, block.timestamp);
    }

    function release() external verifyTimeClaimForUser(){
        require(softcapmet, "LAUNCHPAD: SOFTCAP_WRONG");
        uint256 amount = releasable(msg.sender);
        require(amount > 0, "LAUNCHPAD: AMOUNT_WRONG");
        tokenReleased[msg.sender] += amount;
        TransferHelper.safeTransferFromERC1155(NFT, address(this), msg.sender, tokenId, amount, bytes(''));
        emit Released(msg.sender, amount, block.timestamp);
    }

    function withdraw(address receiver) external onlyCreator(){
        require(block.timestamp >= endTime, "LAUNCHPAD: ENDTIME_WRONG");
        require(softcapmet, "LAUNCHPAD: SOFTCAP_WRONG");
        require(!isWithdrawn, "LAUNCHPAD: WITHDRAW_WRONG");
        uint amount = getBalance();
        isWithdrawn = true;
        if(tokenPayment == WETH){
            TransferHelper.safeTransferETH(receiver, amount);
        }else{
            TransferHelper.safeTransfer(tokenPayment, receiver, amount);
        }
        emit Withdraw(receiver, amount, block.timestamp);
    }

    function startVesting() public view returns(uint256){
        return endTime;
    }

    function duration() public view returns(uint256){
        return vesting;
    }

    function released(address _user) public view returns(uint){
        return tokenReleased[_user];
    }

    function releasable(address _user) public view returns(uint){
        return _vestingSchedule(balanceOf[_user], block.timestamp) - released(_user);
    }

    function getBalance() internal view returns(uint){
        uint amount = (tokenPayment == WETH) ? address(this).balance : IERC20(tokenPayment).balanceOf(address(this));
        return amount;
    }

    function _vestingSchedule(uint totalAllocation, uint timestamp) internal view returns(uint){
        if (timestamp < startVesting() || !softcapmet) {
            return 0;
        } else if ( timestamp > (startVesting() + duration()) ) {
            return totalAllocation;
        } else {
            uint TGE_Amount = totalAllocation * tge / Denominator;
            return ( TGE_Amount + (totalAllocation - TGE_Amount) * (timestamp - startVesting()) / duration());
        }
    }

}
