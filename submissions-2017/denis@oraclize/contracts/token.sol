pragma solidity ^0.4.0;

import "safemath.sol";
import "erc20.sol";

contract MerdeToken is SafeMath, ERC20 {
    function totalSupply() constant returns (uint totalSupply) {
        return tokenSupply;
    } 
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => uint256) balances;
    
    string  public name = "TokenName";
    string  public symbol = "TNM";
    uint256 public price;
    address public owner;
    uint256 public decimals = 6;
    uint256 refundStart;
    uint256 refundEnd;
    uint256 now;
    uint256 end;
    uint256 tokenSupply;

    function transfer(address _to, uint256 _value) returns (bool success){
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success){
        var _allowance = allowed[_from][msg.sender];
        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(_allowance, _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

