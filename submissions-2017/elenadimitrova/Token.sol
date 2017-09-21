pragma solidity ^0.4.13;


contract Token {
    bytes32 public symbol;
    uint256 public decimals;
    bytes32 public name;

    uint256 _supply;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _approvals;

    function Token(uint wad) {
      _balances[msg.sender] = wad;
      _supply = wad;
    }

    function totalSupply() constant returns (uint256) {
        return _supply;
    }

    function balanceOf(address src) constant returns (uint256) {
        return _balances[src];
    }

    function allowance(address src, address guy) constant returns (uint256) {
        return _approvals[src][guy];
    }

    function transfer(address dst, uint wad) returns (bool) {
        assert(_balances[msg.sender] >= wad);

        _balances[msg.sender] -= wad;
        _balances[dst] += wad;

        return true;
    }

    function transferFrom(address src, address dst, uint wad) returns (bool) {
        assert(_balances[src] >= wad);
        assert(_approvals[src][msg.sender] >= wad);

        _approvals[src][msg.sender] -= wad;
        _balances[src] -= wad;
        _balances[dst] += wad;

        return true;
    }

    function approve(address guy, uint256 wad) returns (bool) {
        _approvals[msg.sender][guy] = wad;
        return true;
    }
}
