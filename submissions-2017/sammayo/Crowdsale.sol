pragma solidity ^0.4.11;

contract Crowdsale {
   address public singer1 = 0xca35b7d915458ef540ade6068dfe2f44e8fa733c;
   address public signer2 = 0x14723a09acff6d2a60dcdf7aa4aff308fddc160c;
    
    struct Proposal {
        uint amount;
		address dest;
    }
    Proposal public signer1Proposal;
    Proposal public signer2Proposal;
    
    uint public crowdsaleStart;
    uint public crowdsaleEnd;
    
    function Crowdsale(uint timeTillStart, uint duration) {
        crowdsaleStart = now + timeTillStart;
        crowdsaleEnd = crowdsaleStart + duration;
    }
    
    function withdraw(uint _amount, address _dest) {
    	require(msg.sender == singer1 || msg.sender == signer2);
        require(now > crowdsaleEnd);
        
	    Proposal p;
	    p.amount = _amount;
	    p.dest = _dest;
	    
	    if(msg.sender == singer1) {
	        signer1Proposal = p;
	    } if(msg.sender == signer2) {
	        signer2Proposal = p;
	    }
	    
	    if(signer1Proposal.dest == signer2Proposal.dest && signer1Proposal.amount == signer2Proposal.amount) {
	        address to = signer1Proposal.dest;
	        
	        uint amount = signer1Proposal.amount;
	        if(amount > this.balance) {
	            amount = this.balance;
	        }
	        
	        to.transfer(amount);
	    }
	}
	
	function deposit() payable {
	    require(now > crowdsaleStart);
	    require(now <= crowdsaleEnd);
	}
}