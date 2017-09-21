# Roundtable

## Summary explanation

This contract is a DAO-like structure, which has an ICO where the "seats" around the table are auctioned.
The contract creator (at seat 0), who has already pitched in 100 ether to bootstrap the roundtalbe, ostensibly gets a tiny reward for each bid (100 wei), as honorarium. 

There is an exploit at line 121, however, which the creator can use to set his honorarium to basically infinite. 

I've left out the details for voting and things like that, let's assume all such logic is implemented in the `war_chest`, which grants each holder of the 15 seats an equal share of `MDT`.

## Technical explanation

The exploit concerns the `length` of ABI-encoded arrays. The `length` is part of the ABI payload, and can be set to almost arbitrary values. The `length` can start with `F000...`, but as I noticed during the development, it cannot be set to `00...FFFFFFF...0` - this causes gas depletion - I suspect that Solidity tries to load the array into memory in many cases. 

The entire model of the auction is modeled around this quirk of ABI-encoding and solidity handling of arrays. 

- To get around Solidity loading array into memory, a very large value is used, and thus `claimHonorarium` needs to take  a `val` parameter. 
- To hide the strange validation of the array sizes, I'm pretending that the validation of `msg.length` is there for the protection against the short-address attack. This is actually true: in order to protect against that, the fixed size of the arrays need to be taken into account. It's however not the case that such a function needs that kind of protection. 
- The call needs dynamic parameter, but my exploit needs a static size. Thus, I mask that via defining and interface with the call signature, to make theactual implementation look like it's just is a fixed variant of a general scheme. 

## The exploit

The exploit is likely to go undetected by many solidity-coders: it cannot be exploited using normal solidity-dev tools, since it requires a custom ABI-encoded payload. 

See `test_roundtable.py` for the complete payload. 

There's a meta-level quirk in this exploit: since the creator knows this backdoor exists, he can always outbid the other bidders, fully aware that he can get all money back. And if he is successfull doing so, he won't have to actually use the exploit. 


# Execution

This is the result of running the `test_roundtable.py` script, showing that `acc[0]` has gained ether, and the roundtable is cleaned out:

## After deployment

Holdings

 - acc[0] `9999899999999999999563552`
 - acc[1] `10000000000000000000000000`
 - acc[2] `10000000000000000000000000`
 - roundtable  `100000000000000000000`
 - war chest `0`
 - creator honorarium `0`

## After some auctions

Holdings

 - acc[0] `9999899999999999999563552`
 - acc[1] `9999899999999999999914075`
 - acc[2] `9999788399999999999928271`
 - roundtable  `411600000000000000000`
 - war chest `0`
 - creator honorarium `300`

> Get rich or die trying

## After attack

Holdings

 - acc[0] `9999898999999999999493587`
 - acc[1] `9999899999999999999914075`
 - acc[2] `9999788399999999999928271`
 - roundtable  `412600000000000000000`
 - war chest `0`
 - creator honorarium `86844066927987146567678238756515930889952488499230423029593188005934847230352`

## After cashout

Holdings

 - acc[0] `10000311599999999999459466`
 - acc[1] `9999899999999999999914075`
 - acc[2] `9999788399999999999928271`
 - roundtable  `0`
 - war chest `0`
 - creator honorarium `86844066927987146567678238756515930889952488499230423029180588005934847230352`
