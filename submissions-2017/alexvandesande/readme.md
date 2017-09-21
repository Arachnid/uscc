Underhanded solidity competition
================================

Owner posts an ICO whitepaper, and creates a simple standard token (fixed 1 million token supply, 8 decimal places), transfers it to the crowdsale contract and describes the sale as such:

"No user left behind: the fairer crowdsale in history!"

1) sale will go start when contract is deployed and will last for 7 days
2) price is 1000 tokens per ether, rounded to the 8th decimal place, up to a cap of 1000 ether
3) if sale goes over 1000 ether, then tokens will be distributed in proportion to the total contribution, therefore achieving a fair sale and making sure everyone gets in
4) if cap is not reached, owner will get the remainder of the tokens
5) if a user loses his key and cannot claim his token, he should contact support: all tokens that are unclaimed after 8 weeks will be moved to a multisig contract and be dealt with on a case by case basis


Everyone loves it, the contract is very simple, it works flawlessly on the testnet, and users jump into it, the cap is reached in a few days. But then when users start claiming their tokens a weird thing happens: users are getting fair less than they expected, some are getting nothing at all! A lot of debate happens and developer hires a big time consultant to figure out what happened. Before the audit is published, 8 weeks arrive and suddenly all tokens and ether are gone. 

How to they do it?
------------------

The token is pretty standard except for a small function that allows the owner to change the name, unit and decimal units of it. It shouldn't really matter - those are just for display purposes. Except, they aren't and they are used in these lines of code:

        uint decimalCases =  (10 ** uint(myCoin.decimals()));
        if (totalContributed < cap ) {
            // If under cap get 1000 tokens for every ether
            myTokens = 1000 * contribution[msg.sender] * decimalCases / 1 ether;
        } else {
            // If above cap, then distribute it according to total contributions
            myTokens = contribution[msg.sender] * decimalCases / totalContributed;
        }

It makes sense to use decimalCases in line 4 above, after all we are converting from 1 ether to another unit. But what happens on line 7? Well it seems it shouldn't matter, since it's just a multiplier. But by setting decimals to 0, then myTokens will always return 0, because any individual contribution will always a fraction of totalContribution, and since solidity doesn't handle fractions, it will return 0.


Why wasn't it caught?
---------------------

An experienced solidity developer would certainly get it, but the fact that the order of multiplications matter in solidity is a common error among begginers. At a quick glance, a * b / c == (a * b) / c, but not here. 

Besides, if the decimal is big enough, then the crowdsale contract will work as intended: so it would not be noticed on a test run, unless the owner actually changed the decimal parameter.

Other weird behaviors that should be a red flag: if the cap isn't reach, decimal still plays a role on the amount of contributions, since reducing it to 0 will round any contribution to the finney; also, decimal is an int, not a uint, so it could be a negative number and cause weird behaviors.


What to keep an eye on ICOs
---------------------------

Name, decimals and symbol are just display informations on the token, describing to the end user how to properly display the numbers, be careful whenever using it on actual code. Always pay attention to the order of multiplication.


Final thoughts
--------------

This is my first contribution to an underhanded competition. It's a very basic trick that will probably be spotted quickly, but it reflects a few common traps that I fell in while trying to learn solidity.

Good luck and thanks!

 













