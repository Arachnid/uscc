pragma solidity ^0.4.11;

import '../math/SafeMath.sol';
import './Crowdsale.sol';

/**
 * @title WhitelistedCrowdsale
 * @dev Extension of Crowsdale with a whitelist of investors that 
 * can buy before the start block
 */
contract WhitelistedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  mapping (address => bool) public whitelist;

  function addToWhitelist(address addr) {
    require(msg.sender != address(this));
    whitelist[addr] = true;
  }

  // overriding Crowdsale#validPurchase to add extra whitelit logic
  // @return true if investors can buy at the moment
  function validPurchase() internal constant returns (bool) {
    return super.validPurchase() || (whitelist[msg.sender] && !hasEnded());
  }

}
