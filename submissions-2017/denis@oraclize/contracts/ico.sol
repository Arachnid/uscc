pragma solidity ^0.4.0;

import "token.sol";

// ICO with promise to have a complete and ready product developed, before the end of the ICO
// To guarantee the promise, investors are given up to the last day to request a refund of their investment
// Tokens are priced at a constant rate for simplicity
contract MerdeICO is MerdeToken {

    string  public name = "MerdeToken";
    string  public symbol = "MTN";
    uint256 public price;
    address public owner;
    uint256 public decimals = 6;
    uint256 refundStart;
    uint256 refundEnd;
    uint256 start;
    uint256 end;
    uint256 tokenSupply;
    
    // ICO CONSTRUCTOR 
    
    // Promise to provide working product during ICO period of 1 week
    function MerdeICO() {
        // fixed rate at which tokens are priced
        price = 1000;
        // ico starts immediately on deployment
        start = now;
        // ico ends 1 week after deployment with promise of a finished product
        end = safeAdd(now, 1 weeks);
        // allow refunds at the halfway point of the ICO
        refundStart = end;
        // allow refunds until the last day of the ICO if product undelivered
        refundEnd = safeAdd(now, 2 weeks);
        // set deployer as the owner for later fund redemption
        owner = msg.sender;
    }
    
    // ICO PERIOD functions
    
    // check to ensure it is during the ICO period so funds can be accepted and
    // exchanged for tokens
    function isDuringICO() private constant returns (bool) {
        if (now < end) return true;
        else return false;
    }
    
    // simple payable function to set the sender as the token holder
    function () payable {
        // only allow token creation and acceptance of payment during ICO period
        if (!isDuringICO()) throw;
        
        reserveTokens(msg.sender);
    }
    
    // reserves tokens for users, which become permanent after ico and refund
    // allows proxy recipients
    function reserveTokens(address _recipient) payable {
        if (msg.value == 0) {
          throw;
        }

        uint tokens = msg.value/price;
        tokenSupply = safeAdd(tokenSupply, tokens);

        balances[_recipient] = safeAdd(balances[_recipient], tokens);
    }
    
    // POST ICO PERIOD, Refund stage activates for token holders
    
    // check to ensure it is now the refund period
    function isDuringRefund() private constant returns (bool) {
        if (now > refundStart && now < refundEnd) return true;
        else return false;
    }
    
    // Ability for unsatisfied token holders to get a full refund of their funds
    // Immediately after ICO ends, if they are unhappy with released product.
    function refund() {
        // check to ensure the msg sender actually owns a token balance
        // and whether we are in the refund period for this function to be called
        if (balances[msg.sender] == 0 || balances[msg.sender] > tokenSupply || !isDuringRefund()) throw;
        
        uint savedBalance = balances[msg.sender];
        balances[msg.sender] = 0;
            
        // refund the sender their invested amount and destroy the said tokens
        if(msg.sender.send(safeMul(savedBalance, price))) {
            tokenSupply = safeSub(tokenSupply, savedBalance);
            
        } else {
            // if sending fails, throw and revert state
            throw;
        }
    }
    
    // POST ICO/REFUND Functions for owner to redeem the funds for their project
    
    // check to determine whether we are in the ICO/refund phase or not
    function isDuringRefundAndICO() private constant returns (bool) {
        if (now > start && now < refundEnd) return true;
        else return false;
    }
    
    function ownerRedeemSomeFunds(uint _amt) {
        // check that balance is sufficient with input amount
        // and that it is past the ICO and Refund periods, else throw
        if (_amt > this.balance || _amt == 0 || msg.sender != owner || isDuringRefundAndICO()) throw;
        // owner may redeem chosen amount here from the balance
        owner.send(_amt);
    }
    
    function ownerRedeemAllFunds() {
        // check that balance is sufficient with input amount
        // and that it is past the ICO and Refund periods, else throw
        if (isDuringRefundAndICO() || msg.sender != owner) throw;
        // owner may redeem chosen amount here from the balance
        owner.send(this.balance);
    }
}
