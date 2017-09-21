# ICO Terms

Users can `buy` tokens with ETH at a 1:1 exchange rate. Users can `claim` their
tokens at the end of 30 days. The `community` contract can `release` the tokens
to the developers at their sole discretion; Merde DAO will not launch this
contract, the community can define the control terms and Merde will adopt the
first instance that achieves consensus. There will be a hard fork within 1 year;
any unclaimed tokens at the end of 2 years can be `released` by the developers
directly.

# How to Participate

Use the `buy` function to purchase tokens. Use the `claim` function to receive
your tokens at the end of the crowsdale. Use `refund` to exchange your tokens
proportionally for any unreleased ETH. The community contract can call `release`
to release funds early.

# Spoilers

This contract exploits a problem in the original StandardToken contract that was
widely publicized as de-facto implementation of the ERC20 standard. Treating a
0-valued transfer as invalid is an anti-pattern; it can result in stuck funds
which we used to contrive some rules that would let those funds be redirected to
the developers in a way that they "shouldn't". To perform the attack, do a
0-valued `buy` for each user who submitted a reasonable amount of ETH. This will
cause the `assert(transfer(...))` condition to fail in the `claim` function.

Community "control" in this situation is worthless since they can only `release`
funds to developers; they have milestone "veto" power but are not actually
owners in any sense. The 2 year wait is a long con; those "forgotten" ether will
be releaseable by the attackers themselves.
