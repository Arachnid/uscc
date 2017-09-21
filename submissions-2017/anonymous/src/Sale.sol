pragma solidity ^0.4.13;

import "./StandardToken.sol";

// This sale contract is NOT owned by the devs, it is owned by a well-trusted
// community multisig which can release funds to the developers.
// Users can refund their tokens for unreleased funds at any time.
// After 2 years, the developers can claim any unclaimed funds;
// the assumption is that the community would proactively use the multisig
// to move the funds if the project is failing, but otherwise any excess funds
// are explicitly a bonus to the developers.
contract Sale is StandardToken {
    uint start;
    address community;
    address developers;
    mapping (address => uint[]) buys;
    uint refundable;

    function Sale() {
        community = msg.sender;
        start = time();
    }

    // We override this in our unit tests to simulate a different timestamp
    function time() returns (uint256) {
      return now;
    }

    // Users can purchase tokens on behalf of others, not just for themselvesn
    function buy(address owner, uint amount) payable {
        assert(msg.value == amount);

        // Place a reasonable limit so `claim' doesn't run out of gas
        require(buys[owner].length < 200);

        increaseSupply(amount);
        buys[owner].push(amount);
    }

    // After crowdsale ends, users can claim their tokens
    function claim(address owner) {
        require(time() > start + 30 days);
        for(uint256 i = 0; i < buys[owner].length; i++ ) {
            var amount = buys[owner][i];
            assert(this.transfer(owner, amount));
            refundable -= amount;
        }
    }

    function increaseSupply(uint amount) internal {
        totalSupply += amount;
        balances[this] += amount;
        refundable += amount;
    }

    function refund(uint amount) {
        var share = (amount * refundable) / totalSupply;
        assert(transferFrom(msg.sender, this, share));
        assert(msg.sender.send(share));
    }

    function release(address owner, uint amount) {
        if (msg.sender == community || now > start + 2 years ) {
            assert(developers.send(amount));
            refundable -= amount;
        }
    }

}
