pragma solidity ^0.4.11;

import './StandardToken.sol';

contract UHIToken is StandardToken {
    function UHIToken(uint totalSupply_) {
        totalSupply = totalSupply_;
        balances[msg.sender] = totalSupply;
    }
    function decreaseSupply(address who, uint amount) {
        balances[who] -= amount;
    }
}

contract UHI {
    uint public num;
    struct Purchase {
        address who;
        uint amount;

    }
    Purchase[] purchases;

    address  public judge;
    address  public devs;
    UHIToken public token;
    uint256  public start;
    uint256  icoBalance;

    function UHI(address judge_, address devs_) {
        token = new UHIToken(1000000 ether);
        judge = judge_;
        devs  = devs_;
        start = time();
    }

    function time() returns (uint) {
        return now;
    }

    function isOver() returns (bool) {
        return (time() > start + 7 days);
    }

    function buy() payable {
        assert(!isOver());
        purchases.push(Purchase({
            who: msg.sender,
            amount: msg.value
        }));
    }

    uint public epoch ;
    function milestone() {
        assert(isOver());
        assert(msg.sender == judge);

        uint reward;
        if (epoch >= 4) {
            reward = this.balance;
        } else {
            reward = this.balance / 4;
        }

        devs.transfer(reward);
        epoch ++;
    }

    function distribute() {
        assert(isOver());

        if (icoBalance == 0) {
            icoBalance = this.balance;
        }

        for( var i = 0; i < purchases.length; i++) {
            var purchase = purchases[num + i];
            var allocation = token.totalSupply() * purchase.amount / icoBalance;

            token.transfer(purchase.who, allocation);

            // ensure sufficient gas to complete the call
            if (msg.gas < 50000) break;
        }
        num += i;
    }

    // convert tokens proportionally to un-released ether
    function redeem() {
        assert(isOver());

        if (icoBalance == 0) {
            icoBalance = this.balance;
        }

        var ash = token.balanceOf(msg.sender);
        token.decreaseSupply(msg.sender, ash);

        var give = icoBalance * ash / token.totalSupply();
        msg.sender.transfer(give);
    }
}
