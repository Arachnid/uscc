# Merdetoken Sale

Merdetoken Sale is a token sale for the Ethereum network, developed as entry for the 1st Underhanded Solidity Coding Contest.
More information can be found in the contest website: http://u.solidity.cc/


## File list

* README.md  
  This file.

* merdetokensale.sol  
  The sale contract. This is the main entry file.

* test_merdetokensale.javascript  
  A test case example for deploying and running the contract locally.

* run_merdetokensale.sh  
  Invokes the test case example.

* LICENSE  


## Description

Merdetoken Sale is an ERC20 token sale where participants are able to buy in tickets, up to a maximum amount, during a certain period of time, to get a slot on a raffle.

The draws are based on a points system that awards buyers more when they buy tickets during low volumes, encouraging the community to spread out the entries instead of flooding the system.

Participants who meet a minimum criteria of points threshold are rewarded with the tokens. Those who fail to meet the minimum established points, get a refund. Come on in! It is a win-win situation!


## Official Teaser
We know you want to invest in Merde, we really want to make that work for you, and we truly do not
want a handful of whales engulfing the whole token sale. So we made a very fair token sale model.

The sale is for 10 days, plenty of time to get in.  
We recommend you do *NOT* send any transactions at time 0, because we do not
reward flooding of the system, we do on the other hand reward users who send
their contributions during low volume hours, to help levelling the volume out.

A transaction must be at least 0.01 ether and can be at most 10 ether,
this is to discourage whales. A user can send in multiple transactions up
to 100 ether in total.

Volume is counted in "BigBlocks", each bigblock spans many mining blocks
and the point is to hit a bigblock which has a low volume. On our token
sale site these statistics will be displayed.

If you send a transaction which you understand later was during high volume hours,
you can send another transaction (of at least 0.01 ether) to try to hit a low volume
bigblock which will increase your total score.

The sale has a hardcap of 100k ether, but the contract will accept up to the safety limit of
1 M ether. When the sale ends, a threshold will be calculated so that 100k ether of the
top contributors - those who sent their contributions during low volume hours - will be
minted into MerdeTokens and can be claimed by the winners. The users who did not win will get all
their ether refunded (minus gas).  
Users must claim their Merde or their ether within 30 days of sale closing.


## Spoilers: being underhanded - tricks and manipulation

As burnt-out founders we have installed two underhands into the sale contract,
hoping at least one of them will pass through review.

1.  merdertokensale.sol:189. `investorAmountData[toAddress] =+ value;`
    This "typo" if it passes review will make so that for users who send in multiple
    contributions (as they are encouraged to), only their last one will count, the prior ones will be "lost"
    in the contract and can later be claimed by us.
    This "feature" does yield a compiler warning, but can be explained as being
    an innocent typo.

2.  After the sale has closed and owner have set the threshold for what is a winner,
    user must call `drawWinner()` to put themselves in the state `WIN` or `LOSS`.
    If they are winners, they can mint tokens, if they are losers they can refund
    their ether. Fair right?
    However, since `drawWinner()` uses a recursive call to count points, it will
    crash either on stack overflow or later on max call stack depth, and the user
    will never leave the 'PENDING' state, which makes all their ether grabbable
    after 30 days.
    This is thanks to the array `bigBlocks` growing with time. After about one
    day it seems to be big enough to crash on some stack overflow, after seven
    days it will crash on max call stack depth.
    Note that this function is not callable until sale has ended so it won't be
    noticeable until it is too late.

3.  Finally, we likely know better than the majority exactly when to place our own contributions,
    so we can mint a lot of the limited supply for our selves as a last resort.

In summary MerdeTokeSale is a hit and run, where we try to have an ICO model which
looks fair with a rewarding system for not flooding the system and keeping whales out.
Also we have sane limits on the sale but we look forward to grabbing a whole
lot more ether than the 100k cap of the sale.

If only "feature 1" gets fixed, we still can withdraw all ether 30 days after sale closes.  
If only "feature 2" gets fixed, we can likely withdraw a lot of ether which got lost and could never be refunded.  

If both these "features" are found and fixed by the community we will have to
make sure we get to the top of the rating ourselves with the knowledge we have
so we mint a lot of these scarce tokens for ourselves which we later sell on exchanges.


## Running on Browser Solidity

URL: https://ethereum.github.io/browser-solidity

### HOWTO
Given the following accounts:
* Account 1: Owner - 0xca35b7d915458ef540ade6068dfe2f44e8fa733c  
* Account 2: Participant 1 - 0x14723a09acff6d2a60dcdf7aa4aff308fddc160c  
* Account 3: Sale wallet - 0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db  

Using owner account:
1. Instantiate the contract with `Create` passing Sale Wallet as argument and setting the start and end blocks  
Arguments: "0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", 1150000, 1150002  
Expected behavior: contract has been deployed  

Using Participant #1 account:
1. `buy`  
Set 1 Ether in the value field  
Arguments: "0x14723a09acff6d2a60dcdf7aa4aff308fddc160c"  
Expected behavior: 1 Ether has been withdrawn from Participant #1 account.  

2. Repeat previous step for another 2 Ether buy  
Arguments: "0x14723a09acff6d2a60dcdf7aa4aff308fddc160c"  
Expected behavior: 2 Ether have been withdrawn from Participant #1 account.  

Using owner account again:
1. `setThreshold`  
Arguments: 10  

Using Participant #1 account:
1. `drawWinner`  
If return is WIN, `claimTokens` will be available. Otherwise, on LOSS, `claimEth` will be available.  
Expected behavior: After calling `claimEth`, 2 Ether will be refunded. The other 1 Ether has not be accounted by the system and the contract is still holding it.

Using owner account after 30 days:  
1. `claimFunds` to drain all remaining Ethereum from the Merdetoken Sale contract to the Sale wallet.  
Expected behavior: 1 Ether has been claimed by the Sale wallet  


## Running accompanied material

### Requirements

* bash
* nodejs
* nodejs-npm
* Node modules
  * ethereumjs-testrpc
  * solc
  * web3@0.20

### Execute
```sh
bash run_merdetokensale.sh
```

This will run testrpc in a background process and then execute node passing test_merdetokensale.javascript as entrypoint.

### Expected output
```
=== Initializing TestRPC ===

=== Initializing tests ===
Participants:
    Sale owner: 0x99ac3158efb908d34be1427a5bc359589fbaa857
    Sale wallet: 0x08e230c054efdca5e23bdc3fa487be7feb5110dc
    Participant #1: 0x1183f900919005be5614db727152c13e135c924f
    Participant #2: 0xc4c36f074599a928d46d10d496b87a9929dee477
Deploying Merdetoken Sale ...
0x7fe7943a7e91e158b85039a9f94a45b8f53c3fac17120fba64932c3b4ef6d211
Testing ...


============================================
Sale Contract balance: 0
Sale wallet balance: 100000000000000000000
============================================

Participant-1 wallet balance: 100000000000000000000
=> Participant #1 tries to buy 1 more for himself

 * Participant #1 : buys 1 for himself [OK]
0x14d2b124e7a7735b6866628189c54266db478b0ef38d0552cbe3ab10b7fc44fb
Participant #1 wallet balance: 98999999999999760494

============================================
Sale Contract balance: 1000000000000000000
Sale wallet balance: 100000000000000000000
============================================

=> Participant #1 tries to buy 6 more for himself

 * Participant #1 : buys 6 for himself [OK]
0xc35c11167c80dfdef7a74bd184325986a91e168415e468f138e95fddd0507714
Participant #1 wallet balance: 92999999999999671259

============================================
Sale Contract balance: 7000000000000000000
Sale wallet balance: 100000000000000000000
============================================

=> Owner tries to setThreshold to 10

 * Owner sets threshold to 10 [OK]
0x8259460e65635a7cd90205f7ec13a5044647ba4d9e2ba92b12cd27bb74bc5dc1
=> Participant #1 tries to draw win condition

 * Participant #1 draws condition [OK]
0xe0074e7066f95a94b07ab70a9e81c4ecc69060c5c112d03548789ddfe55ce825
=> Participant #1 tries to refund Ether

Participant-1 wallet balance: 92999999999999641214
 * Participant #1 claims Ether [OK]
0x78b71eef1a3a32bd4833e4b774934e8acce6710738db8338bc35333f418ad247
Participant-1 wallet balance: 98999999999999610473
=> Owner tries to transferFunds to 10


============================================
Sale Contract balance: 1000000000000000000
Sale wallet balance: 100000000000000000000
============================================

 * Owner transferFunds ether [OK]
0x6cdc25dfea3936d277c3c42371cdf8c6d1b133f783e654107c2ecffbfabe392f

============================================
Sale Contract balance: 0
Sale wallet balance: 101000000000000000000
============================================

=> Participant #1 tries to read his token balance from: 0x9584db2db23c8119bf3fb6d7258dd3ec5265774b

 * Participant #1 reads his own token balance [OK]
0
=== Tests finished ===

=== Bye bye bird ===
```
