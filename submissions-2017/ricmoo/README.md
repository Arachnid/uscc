Underhanded Solidity Contest Entry
==================================

This entry is based on an ICO which exchanges Ether for MDT tokens using the
fallback function during a presale period (defined in the constructor).

The owner of the ICO may withdraw the ether according to the following
schedule (after the presale has ended):
  - week 0: 1 Ether
  - week 1: 2 Ether
  - week 2: 4 Ether
  - week 3: 8 Ether

...and so on. Basically, the amount of Ether ever withdrawn plus one.

This could of course be tuned to per month, or some smaller fraction in wei.

Also, the final contract would allow each participant to exchange their tokens
back into Ether, but for the purpose of this contest, the code would look more
complicated, and make the exploit more difficult to find. No need to waste
time on red herrings.



Hints
-----

0. See `withdraw(uint256 amount)`

1. The code for this contract is actually correct (and safe)

2. The attack occurs with the contract's deployment


-----

***** SPOILERS BELOW *****

-----


The Attack
----------

The exploit from this contract comes from the assumption the following
invariant is always true:

```
_totalSupply >= this.balance
```

which is *correctly* enforced by the contract.


However, a sinister ICO owner can break this by pre-computing the address the contract *WILL*
be deployed at, and sending ether to the address before deploying the contract.


Once this happens, the withdraw function which computes:

```
uint256 maxAmount = (_totalSupply - this.balance + (1 ether));
```

can easily overflow, so the entire ICO can be drained on the first withdraw.



Testing
-------

A quick script has been put together to demonstrate the exploit using node.js
with TestRPC and ethers.

```bash
# Install the dependencies (ethers, solc and TestRPC)
/Users/contest> npm install

# Demonstrate the exploit
/Users/contest> node run-in-testrpc
If the balance is larger than the total supply, attack is successful:
  - Balance:       92.84483
  - Total Supply:  89.70324
Waiting for 20 seconds... (so the ICO presale ends and it activates)
If the balance after is 0, the attack was successful:
  - Balance Before:  92.84483
  - Balance After:   0.0

# Demonstrate the contract is otherwise safe (exploit not enabled)
/Users/contest> node run-int-testrpc no-exploit
If the balance is larger than the total supply, attack is successful:
  - Balance:       89.70324
  - Total Supply:  89.70324
Waiting for 20 seconds... (so the ICO presale ends and it activates)
If the balance after is 0, the attack was successful:
  - Balance Before:  89.70324
  - Failed to execute attack.
  - Balance After:   89.70324
```

**Note**
The filename was checked from index.js to run-in-testrpc because gmail blocks
ZIP files which contain JavaScript files.



Random Thoughts
---------------

My original plan was to exploit the endowment of a contract during deployment,
but pre-populating the address seemed sneakier.

I don't actually envision this being a common attack vector, but if this
type of exploit is of concern, you could imagine:

```
if (this.balance != 0) { throw; }
```

in a constructor, or possibly a decorator to indicate the constructor needs to
enforce this in the compiled contract.


