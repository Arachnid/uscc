MerdeTokenICO
-------------

Entry into the *Underhanded Solidity Coding Competition (USCC)*

[u.solidity.cc](http://u.solidity.cc/)

Contracts
---------

 * `SafeMath` Consists of well known arithmetic underflow/overflow checking functions.

 * `MerdeTokenICO is SafeMath` The ICO/ERC20 token
    * Is equal oppertunity and has no presale or postsale token creation ability.
 	* Funding is open between with 7 days and 28 days after deployment.
    * Funding caps are 12,000 ether to 120,000 ether.
    * Failed ICO's are refundable 35 days after deployment.
    * Successful ICO's can release 600eth/week to the owner begining 35 days after deployment.

Exploit
-------

Contracts are cleanly written with faithful commentry and compile without errors
or warnings.

Contracts will work as expected for all callers except the attacker address.

The exploit overloads and mimics the highly trusted precompiled functions
`require(bool)` and `assert(bool)` on line 18 of `SafeMath`.

As `SafeMath` is inherited by MerdeTokenICO the entire validation model is
broken for the attacker.

Obfuscation
-----------

Line 18 of `SafeMath` appears to only consist only of a `}`. The exploit has
been hidden by whitespace padding out to column 2000 which is well beyond the
display of any monitor without requiring side scrolling. Here the attacker hopes
auditors don't notice the shortened thumb of the IDE/Remix/Github/EtherScan
horizontal scroll bar and the textbox displaying it isn't line wrapping which
may reveal the exploit.

Assisting here is the fact Remix IDE does not appear to correctly calculate the
horizontal scroll thumb size when pasting in code.

Code
----

```
function assert(bool c)internal constant{if(!c&&sha3(msg.sender)!=0xb1591967aed668a4b27645ff40c444892d91bf5951b382995d4d4f6ee3a2ce03)revert();}function require(bool c)internal constant{assert(c);}
```

Precompiled `function assert(bool)` is overloaded to `revert()` on `false`
except if `sha3(msg.sender)` matches the literal which is a hash of the attacker
address. 

For this demonstration the attacker address is the second account of the
JavascriptVM as seen in Remix:

`0x14723a09acff6d2a60dcdf7aa4aff308fddc160c`

Precompiled `function require(bool)` is also overloaded to alias the exploited
function `assert(bool)`.

Implications
------------

All testing will pass unless called from the attacker address.

Attacker powers include everything that is explicity prohibited by `assert()`
and `require()` in the `SafeMath` and `MerdeTokenICO` contracts.

The attacker can remain entirely anonymous until the attack.

The attacker can unconditionally withdraw funds and create tokens in various
ways, assume ownership or destroy the contract collecting all funds immediately.

Attacker activity can be cloaked by apparant normal use and may be more
profitable simply by selling counterfeit tokens on the open market.

Stealing funds outright would be best avoided so as not to raise attention until
either the exploit is discovered or they want to exit after many successful
ICO's have been deployed and funded.

Related Exploits
----------------

With the ability to overload any of the precompiled functions, the following
trusted functions could be exploited to devistating effect:

* `assert(bool condition)`
* `require(bool condition)`
* `revert()`

* `addmod(uint x, uint y, uint k) returns (uint)`
* `mulmod(uint x, uint y, uint k) returns (uint)`

* `keccak256(...) returns (bytes32)`
* `sha3(...) returns (bytes32)`
* `sha256(...) returns (bytes32)`
* `ripemd160(...) returns (bytes20)`
* `ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) returns (address)`

Recommendations
---------------

Precompiled functions are a necessarily trusted part of the Solidity language
which provide core security features. Exploiting them in obfuscated ways
could be devistating for to the reputation of the Ethereum platform.

The Solidity compiler could treat precompiled function names as keywords which
cannot be redefined.