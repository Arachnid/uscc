The MDT crowdsale is a hotly anticipated event, with the MDT offerors laying
out the following details on a crowdsale:

- 50k ETH crowdsale cap; once cap is reached, crowdsale ends. No more than 50M tokens
  can ever be created, providing a limited supply.  1:1 Wei:Token exchange rate.
- Preferred investor status; our friends and family at MDT are eligible to buy
  coins early, before the crowdsale starts and the riff raff get in.
- Instant trading; our ERC20 will launch right away on the blockchain.
- The crowdsale is run for 100000 blocks (~17 days)
- No take backs; if the cap is not reached, the ERC20 runs anyway.

The contract to be launched on the blockchain is MDTCrowdsale.sol.

Unfortunately, the programmer of the MDT crowdsale made a one line "mistake" that
he will trigger, to turn the MDT crowdscale into a widespread and very public
disaster.  The diff to the working contract as described above is one line; can you
find it?

Hint: you can easily write a full coverage unit test suite for MDTToken.sol without 
revealing the bug!

Hint2: The bug violates one of the invariants in this README.

Happy hunting!

(This entry is inspired by an unnamed real contract developed for production use.)
(Note: some source files shamelessly ripped from Zeppelin and Consensys Githubs.)
