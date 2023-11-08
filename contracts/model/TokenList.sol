pragma solidity ^0.8.2;
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenList is Ownable {
    
    bool public status;

    mapping(address => bool) private state;
    
    event SetState(
        address token,
        bool status,
        uint blockTime
    );

    event SetStatus(
        bool status,
        uint blockTime
    );
    
    function setState(address token, bool _status) external onlyOwner(){
        require(token != address(0), "TOKENLIST: TOKEN_WRONG");
        state[token] = _status;
        emit SetState(token, _status, block.timestamp);
    }

    function setStatus(bool _status) external onlyOwner(){
        status = _status;
        emit SetStatus(_status, block.timestamp);
    }

    function getState(address token) external view returns(bool){
        bool isState = status ? true : state[token];
        return isState;
    }
}