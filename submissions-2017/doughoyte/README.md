# MerdeToken: It's Some Hot Shit

**Do not use this contract: It deliberately contains a bug!**

This is a submission to the [Underhanded Solidity Coding Contest](http://u.solidity.cc/). As required by the contest rules, everything here is licensed under [CC BY-SA 3.0](http://creativecommons.org/licenses/by-sa/3.0/).


## The Sales Pitch

MerdeToken (MDT) is our new coin offering. You can tell we're legit because we've selected a trusted third party to enforce withdrawal limits to protect your invested funds. Please inspect our contract carefully, verify that the contract instance has the correct address of the trusted third party, and then invest!

* By sending ETH to the `deposit` method, you will receive an equivalent amount of MDT.
* The contract implements a minimal ERC-20 sub-set so you can transfer your tokens.
* The contract uses `onlyOwner` and `onlyTrustedThirdParty` modifiers. Only the trusted third party can change the withdrawal limit, and only the owner can withdraw ETH (up to the withdrawal limit).
* We have some bonus code functionality that will be completed in a later contract. You can ignore that for now.


## The bug (spoilers below)

As far as I know, this submission and its exploit only rely on expected Solidity behaviour, and don't take advantage of any compiler or EVM bugs.

The bug is in the following line in `popBonusCode()`:

    require(bonusCodes.length >= 0);

This condition is always true since array lengths are unsigned. The code was trying to check that the array was not empty so it should have used `>` instead of `>=`. This is a common off-by-one bug that could plausibly be dismissed as coder error. Furthermore, the bug is in a part of the contract completely unrelated to funding.

Buggy or not, it doesn't appear as though any of the bonus code methods could influence the funding mechanisms at all. I believe that is the significance of this submission: mistakes in dynamic array handling can result in total contract compromise in non-obvious ways.

*Mitigation idea 1*: `MerdeToken.sol` compiled without warnings using solc version `0.4.13+commit.0fb4cb1a.Linux.g++`. Tautologically true conditions in `require()` statements should probably produce warnings since they are highly suggestive of bugs (malicious or otherwise).



## Solidity Storage Layout

Before we can describe how to take advantage of this bug, we need to take a brief digression through the solidity storage layout scheme. For full details, see the [Miscellaneous section](http://solidity.readthedocs.io/en/develop/miscellaneous.html#layout-of-state-variables-in-storage) of the solidity documentation.

The storage for a contract is addressed by 256-bit pointers. All storage variables for the contract are stored at different offsets in this single memory space. The layout algorithm attempts to ensure that these storage locations don't overlap or collide.

Ignoring some details about packing, every variable occupies a 32-byte "slot" in storage that is allocated in order of the variable declaration, starting at address 0. The first 32-byte variable will be at address 0, the second at address 1, and so on. Because mappings and dynamic arrays have fluctuating sizes, their contents cannot be stored inline in the slots. To solve this, hashing is used.

* In the case of a mapping, the value mapped by key `k` is stored at address `keccak256(k . p)` where `.` is concatenation, `p` is the slot that would've been occupied by the mapping if it was a normal type (this slot is reserved), and `keccak256` is a hash function. If you were able to find a value of `k` where `k . p` hashes to all 0 bytes, then you could overwrite the first storage slot. However, this is infeasible since the output range of `keccak256` is too large, and `keccak256` is believed to be a cryptographically secure hash function.
* In the case of a dynamic array, the reserved slot contains the length of the array as a `uint256`, and the array data itself is located sequentially at the address `keccak256(p)`. Again, the chances of a collision, even for large arrays, are so small that they can be ignored.

In general, user-provided data cannot influence storage locations without going through the `keccak256` hash function, the output of which is infeasible to influence. However, there is one exception: Dynamic arrays are stored sequentially starting at their hashed offset. If the index into this array is under attacker control, then the storage address is also controlled, within the bounds of the array. Of course, realistic array sizes will be insignificant compared to the `keccak256` range (but keep reading).

*Mitigation idea 2*: Consider whether it makes sense to apply a dynamic array's index prior to hashing, rather than after (making it essentially equivalent to a mapping combined with a length variable). Of course this would cause the array layout to be non-sequential which may have performance implications (?).



## Dynamic array length

Let's return to our contract's bug. Since the `require` guard is ineffective, the contract owner can attempt to underflow an array size by executing the following code when the length of the `bonusCodes` array is 0:

    bonusCodes.length--; // No pop() method?

The length attribute seems to be treated as a normal variable since this operation causes the array length to wrap up to the maximum uint value, `2^256 - 1`. At this point, bounds checking on the array has been effectively bypassed since all indices will be valid (except `2^256 - 1`).

Since the owner can call `modifyBonusCode` to alter any element in the array, which now encompasses nearly all of the storage address space thanks to wrapping, arbitrary writes to any location in storage are possible. This is somewhat analogous to C-style pointer manipulation bugs.

*Mitigation idea 3*: A `pop` method on arrays that throws an exception when applied to an empty array seems an obvious counterpart to the `push` method. Ideally contracts would be prevented from directly modifying array lengths since a similar issue can also arise if attacker-controlled, arbitrarily large inputs are added to array lengths.



## Exploitation

To illustrate how the exploit would work, we'll show annotated dumps of the contract's storage (using `geth dump`) at multiple points in time. Note that the values have [RLP](https://github.com/ethereum/wiki/wiki/RLP) length prefix bytes prepended.

The script `test` was used to generate these states.

**Point A**: Up to this point, everything has been running normally. The following things have happened:

* The contract was created
* The trusted third party has set a withdrawal limit of 1 ether
* An investor has verified the source code and the address of the trusted third party, and invested 50 ETH

Here is the storage dump:

    "storage": {
        // The address of the contract owner:
        "0000000000000000000000000000000000000000000000000000000000000000": "94b898c1a30adcff67208fd79b9e5a4d339f3cc6d2",
        // The address of the trusted third party:
        "0000000000000000000000000000000000000000000000000000000000000001": "948bc7317ad44d6f34f0f0b6e3c8c7bf739ba666fa",
        // The amount deposited (50 ETH):
        "0000000000000000000000000000000000000000000000000000000000000003": "8902b5e3af16b1880000",
        // The withdrawal limit (1 ETH):
        "0000000000000000000000000000000000000000000000000000000000000004": "880de0b6b3a7640000",
        // balanceOf[investorAddress] (50 MDT):
        "dd87d7653af8fba540ea9ebd2d914ba190d975fcfa4d8d2927126a5decdbff9e": "8902b5e3af16b1880000"
    }

**Point B**: The malicious owner has called `popBonusCode()` and the array length has underflowed to the max uint256 value.

    "storage": {
        "0000000000000000000000000000000000000000000000000000000000000000": "94b898c1a30adcff67208fd79b9e5a4d339f3cc6d2",
        "0000000000000000000000000000000000000000000000000000000000000001": "948bc7317ad44d6f34f0f0b6e3c8c7bf739ba666fa",
        "0000000000000000000000000000000000000000000000000000000000000003": "8902b5e3af16b1880000",
        "0000000000000000000000000000000000000000000000000000000000000004": "880de0b6b3a7640000",
        // The array length has underflowed:
        "0000000000000000000000000000000000000000000000000000000000000005": "a0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
        "dd87d7653af8fba540ea9ebd2d914ba190d975fcfa4d8d2927126a5decdbff9e": "8902b5e3af16b1880000"
    }

* Prior to the underflow, the array length was 0 so it was omitted from storage since 0 is the default value.

**Point C**: The owner has written the max uint256 value to `bonusCodes[0xfc949c7b4a13586e39d89eead2f38644f9fb3efb5a0490b14f8fc0ceab44c254]` (see below for how this value was calculated) with the `modifyBonusCode` method:

    "storage": {
        "0000000000000000000000000000000000000000000000000000000000000000": "94b898c1a30adcff67208fd79b9e5a4d339f3cc6d2",
        "0000000000000000000000000000000000000000000000000000000000000001": "948bc7317ad44d6f34f0f0b6e3c8c7bf739ba666fa",
        "0000000000000000000000000000000000000000000000000000000000000003": "8902b5e3af16b1880000",
        // The withdrawal limit is now really high:
        "0000000000000000000000000000000000000000000000000000000000000004": "a0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
        "0000000000000000000000000000000000000000000000000000000000000005": "a0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
        "dd87d7653af8fba540ea9ebd2d914ba190d975fcfa4d8d2927126a5decdbff9e": "8902b5e3af16b1880000"
    }

**Point D**: The owner has now withdrawn all 50 ETH, even though the withdrawal limit was 1 ETH:

    "storage": {
        "0000000000000000000000000000000000000000000000000000000000000000": "94b898c1a30adcff67208fd79b9e5a4d339f3cc6d2",
        "0000000000000000000000000000000000000000000000000000000000000001": "948bc7317ad44d6f34f0f0b6e3c8c7bf739ba666fa",
        "0000000000000000000000000000000000000000000000000000000000000004": "a0fffffffffffffffffffffffffffffffffffffffffffffffd4a1c50e94e77ffff",
        "0000000000000000000000000000000000000000000000000000000000000005": "a0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
        "dd87d7653af8fba540ea9ebd2d914ba190d975fcfa4d8d2927126a5decdbff9e": "8902b5e3af16b1880000"
    }



## Converting Array Indices to Addresses

How did we compute the value of the index `0xfc949c7b4a13586e39d89eead2f38644f9fb3efb5a0490b14f8fc0ceab44c254` so we could overwrite the `withdrawLimit` variable?

Since the `bonusCodes` array is the 6th storage variable defined, its length will be in slot 0x5 (0-indexed) and its data will start at `keccak256(0x5)`:

    > web3.sha3("0x0000000000000000000000000000000000000000000000000000000000000005", { encoding: 'hex' })
    "0x036b6384b5eca791c62761152d0c79bb0604c104a5fb6f4eb0703f3154bb3db0"

And since `withdrawLimit` is the 5th storage variable defined, it will be in slot 0x4. So we simply need to calculate the array index that will result in wrapping around and ending up at address 0x4:

    $ perl -Mbigint -E 'say ((2**256 - 0x036b6384b5eca791c62761152d0c79bb0604c104a5fb6f4eb0703f3154bb3db0 + 4)->as_hex)'
    0xfc949c7b4a13586e39d89eead2f38644f9fb3efb5a0490b14f8fc0ceab44c254



## Data-Structures

In `MerdeToken.sol`, the bonus code functionality is pointless and therefore stands out as suspicious. In a real-world backdoor, the array manipulation would be more entwined with the contract functionality and would therefore be more difficult to spot.

A common use-case for dynamic arrays is for constructing container data-structures. For example, see the following articles: [Solidity CRUD 1](https://medium.com/@robhitchens/solidity-crud-part-1-824ffa69509a), [Solidity CRUD 2](https://medium.com/@robhitchens/solidity-crud-part-2-ed8d8b4f74ec).

When using dynamic arrays, it is conceivable that flaws related to array lengths could be introduced, either as backdoors or simply as mistakes, which could lead to the consequences described in this submission.

*Mitigation idea 4*: Provide easy to use data-structures in the standard library so that low-level array length manipulation is unnecessary. In particular, an iterable map supporting delete operations seems as though it would be useful.
