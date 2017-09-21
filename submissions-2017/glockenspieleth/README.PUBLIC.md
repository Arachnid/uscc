# Underhanded ~~Investment~~ Innovation

## ~~Investment~~ Donation of a Lifetime!

Cryptocoins have seen returns of thousands of percentage points in recent years.
Everyone's been getting rich without you, but now it's your turn to cash in on
the crypto paradigm shift! Get UHI TODAY!

![Hocky stick graph](http://www.moneydiva.com/wp-content/uploads/2014/06/MD-Hockey-stick-graph.jpg)

_Projected profits, totally legit._


## What does UHI do?

UHI is a wealth-redistribution scheme designed to siphon money away from
institutional accounts and move it into the crypto-economy. Through
distributed ledger technology, UHI will allow spending of collectively-held
funds in accordance with the number of tokens redeemed by ~~investors~~
donators. ETH contributed will be used for awesome things, trust us.


## ICO Structure

The ICO will run for seven days.

There will be four development epochs, each granting a quarter of the ETH left
in the contract to the development team. After the fourth epoch has passed, the
development team may claim the remainder of the funds in the contract. The
advancement of epochs will be performed by a Judge account.

Refunds may be claimed for as long as ETH remains in the smart contract.
Claiming a refund grants the claimant a portion of the ETH in the contract
proportionate to their token balance. The claimant's tokens are then
burned.


## Participating

If you haven't already, [create a
wallet](https://www.myetherwallet.com/#generate-wallet).

1. Go to [MyEtherWallet](https://myetherwallet.com).
2. Click "Contracts" on the menu bar.
3. In the "Contract Address" field, enter
   `0xico-address-goes-here`
4. In the "ABI / JSON Interface" box, copy and paste [the code
   here](https://github.com/dapphub/underhanded-ii/UHI.abi).
5. Click "Access"
6. Click "Select a Function"
7. Click "buy" in the dropdown list.
8. Click the "Write" button.
9. Enter the amount of ETH you'd like to send in the "Amount to Send" box.
10. Click the "Generate Transaction" button.
11. Click "Yes, I am sure! Make transaction."
12. Wait until the ICO is over.
13. Anyone may call `distribute` repeatedly to distribute tokens to the ICO
    participants.

At any point after the ICO, you may also choose to call `redeem` and exchange
the tokens in your account for ETH. To only exchange part of your balance, just
send the tokens you intend to keep to another address.

Now you've got UHI!


## Developer Overview

The token builds on a base contract called `DSTokenBase`, which provides a
simple ERC20 token implementation. The constructor takes the number of tokens to
create initially, one million in this case.

The `UHI` contract constructor starts the ICO as soon as the contract is
deployed by setting a `start` property to `now`.

The `isOver` function returns a boolean indicating whether the ICO period has
passed.

The `buy` function is `payable` and keeps track of the funds each contributor
has donated.

The `milestone` function may only be called by the `judge` account after the ICO
is over. This advances the current `epoch` and distributes funds to the
developers.

The `distribute` function may be called by anyone once the ICO is over. It
iterates over the array of contributors and distributes tokens based on how much
ETH each contributor donated until the transaction is almost out of gas. It then
saves the index number of the last contributor to receive their tokens, allowing
the function to continue on from where it left off the next time it's called.

The `redeem` function gets the token balance of the user sending the
transaction, burns the user's entire balance, and then sends an amount
of ETH to the user proportionate to the percentage of the total donation amount
they contributed and the amount of ETH contributed to the contract. In other
words, if the user has 100,000 UHI of the 1,000,000 UHI total supply, and the
contract contains 10 ETH, the user will receive 1 ETH in exchange for their
100,000 UHI.


## Disclaimer

_Funds sent to this ICO are to be considered a donation, with no guarantee or
expectation of return. This will definitely not make you rich overnight.
&ast;wink&ast;_
