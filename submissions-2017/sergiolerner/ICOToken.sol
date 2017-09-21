pragma solidity ^0.4.8;
  
 // ----------------------------------------------------------------------------------------------
 // Simplified fixed supply token contract adapted for an ICO
 // ----------------------------------------------------------------------------------------------
  
 contract ICOTokenWithLeadInvestor {
    function getLeadInvestor()   returns(address lead);
 }
 
 contract ICOTokenManager  {
    function ICOEnded() payable;

 }

 contract ICOToken is ICOTokenWithLeadInvestor {
     string public constant symbol = "ICO";
     string public constant name = "TheICO Token";
     uint8 public constant decimals = 18;
     uint256 public leadInvestorAmount = 300 ether; 
     uint256 _totalSupply = 0;

     // The block number this ICO ends. Zero means it's inactive, already ended
     uint ICOEnds;
     
     // Address to transfer the funds after the ICO is over
     ICOTokenManager public projectMultisigWallet;
     
     address public leadInvestor;
     
     // Balances for each account
     mapping(address => uint256) balances;


    modifier ICOActive() {
         if ((block.number < ICOEnds) || (ICOEnds==0)) {
             throw;
         }
         _;
     }
     
    modifier ICOJustEnded() {
         if ((block.number >= ICOEnds) && (ICOEnds==0)) {
             throw;
         }
         _;
     }
     
     // Constructor
     function ICOToken() {
         projectMultisigWallet = ICOTokenManager(msg.sender);
         ICOEnds = block.number + 5*60*24*7; // Aproximately 7 days, at an average 20 seconds per block
     }
  
     function buyTokens() payable {
        _totalSupply +=msg.value;
        balances[msg.sender] += msg.value;
        
        if (leadInvestor!=0)
        if (balances[msg.sender]>leadInvestorAmount) {
            leadInvestor =msg.sender;
        }
     }
     
     function ICOEnded() ICOJustEnded {
	     // First deactivate the ICO so that no user can continue sending funds
         ICOEnds =0;
		 
		 // Now move the ICO ethers to the manager contract and the manager contract will pull the lead investor
         projectMultisigWallet.ICOEnded.value(this.balance)();
    }
    
    function getICOEnds() constant returns (uint256 b) {
         b = ICOEnds;
     }
     
    function getCurrentBlockNumber() constant returns (uint256 b) {
         b = block.number;
     }     
     
    function getBalance() constant returns (uint256 b) {
         b = this.balance;
     }
     
     function totalSupply() constant returns (uint256 totalSupply) {
         totalSupply = _totalSupply;
     }
  
     // What is the balance of a particular account?
     function balanceOf(address _owner) constant returns (uint256 balance) {
         return balances[_owner];
     }
     
    function getLeadInvestor() returns(address lead) {
        return leadInvestor;
    }
 }