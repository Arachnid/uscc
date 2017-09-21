
# Description
This Underhanded ICOs entry is based on basic ICO model which enables investors to
destroy their token and recollect their contributions up to 30 days after the end of the crowdsale. 

In most cases, most public scrutinity is given to an ICO project in the last stage or after a crowdsale
has been completed. This is due to the increases media exposure that project get during the ICO period.
This ICO model enables investors to reconsider their contribution after having acquire more useful information.

# Underhanded Part
Investors have two balances accredited in the contract: one token balance and one ether balance. 
Both balances are defined under a mapping which has as key a string and as value an address to uint mapping. 

mapping(string => mapping (address => uint)) balances;

The strings used as key are: 

	* 'token': the number of tokens received
	* 'refunds': the number of wei contributed

The underhanded part of this ICO is limited to the function refundTokenHolder(). The function is the following one:

	function refundTokenHolder() specialPeriod {
	    require(balances['token'][msg.sender] != 0);
	    
	    delete balances['token'][msg.sender];
	    uint weiAmount = balances['rеfunds'][msg.sender];
	    if (msg.sender.send(weiAmount)) {
	        delete balances['refunds'][msg.sender];
	    }
	}

The user expectation is that the function will refund the entire wei balance of the user, and delete the token balance of the user.
But the function, instead, will only delete the tokens and no balance will be accredited. This is achieved via an homoglyph attack.

	// The e in the 'refunds' string is the unicode char U+0435, also known as Cyrillic small ie  
	uint weiAmount = balances['rеfunds'][msg.sender];

Since the mapping is not initialized, weiAmount will be zero.
	// The e in the 'refunds' string is the Latin e or unicode char U+0065
	delete balances['refunds'][msg.sender];

The net effect of this function is deleting the user balance without refunding the user contribution. 
