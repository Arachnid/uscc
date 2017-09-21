// Note for Judges: This is based on the Minimum Viable Token from https://www.ethereum.org/token
// We made it into a revenue-based token:
// After the ICO, all customers of the new company pay directly to this contract.
// Then, the contract distributes the fund according to token shares.
// E.g. Customer calls distribute() with 1 ETH, address a has 4 tokens, address b has 2 tokens, address c has 2 tokens.
// => a gets 0.4 ETH, b gets 0.2 ETH, c gets 0.2 ETH
pragma solidity ^0.4.11;

import "./ItMap.sol";
import "./InternallyPausable.sol";

contract MyToken is InternallyPausable {
	event Transfer(address tokenHolder, uint256 tokenBalance, uint256 fundsForHolder);
    /* This creates an iterable mapping with all balances */
    ItMap.itmap public balanceOf;

	/* When distributing funds, we can likely not distribute everything, as it cannot be devided equally.
       Example: We receive 1 ETH and 9 tokens. A residue will remain.
	   We store the residue and use it during the next fund distribution. */
	uint256 fundResidue;

	/* Total number of tokens */
	uint256 numTokens;

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function MyToken(uint256 initialSupply) {
		// Give the creator all initial tokens
        ItMap.insert(balanceOf,msg.sender, initialSupply);
		// Save the number of total tokens
		numTokens = initialSupply;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) whenNotPaused {
		// Check if the sender has enough
        require(balanceOf.data[msg.sender].value >= _value);
		// Subtract from the sender
        balanceOf.data[msg.sender].value -= _value;
		// Add the same to the recipien
        ItMap.insert(balanceOf, _to, balanceOf.data[_to].value + _value);
    }

	/* Distribute funds */
	function distribute() whenNotPaused payable {
		// Tokens that already received a share of the distribution 
		uint256 remainingTokens = numTokens;
		// Total funds available during distribution
		uint256 totalFunds = fundResidue + msg.value;
		// New Residue
		fundResidue = totalFunds % numTokens;
		// Check if there is too little to distribute
		if(fundResidue == totalFunds){
			return;
		}
		// Now we know that totalFunds can be evenly divided among token holders
		totalFunds -= fundResidue;
		// Pause to protect against Re-entrancy attacks
		pause();
		// Iterate over token holders
	    for (var i = ItMap.iterate_start(balanceOf); ItMap.iterate_valid(balanceOf, i); i = ItMap.iterate_next(balanceOf, i)){
			// Get the address and the balance of the tokenholder
		    var (tokenHolder, tokenBalance) = ItMap.iterate_get(balanceOf, i);
			// Compute share of the funds
			uint256 fundsForHolder = tokenBalance/remainingTokens * totalFunds;
			// Transfer share of the funds
			tokenHolder.transfer(fundsForHolder);
			// Update the state
			remainingTokens -= tokenBalance;
			totalFunds -= fundsForHolder;
	    }
		// Unpause as we have finished the critical part
		unpause();
	}
}
