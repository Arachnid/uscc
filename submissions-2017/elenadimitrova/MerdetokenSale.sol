pragma solidity ^0.4.13;

import "./Token.sol";


contract MerdetokenSale {
  // Block number in which the sale starts. Inclusive. Sale will be opened at start block.
  uint public startBlock;
  // Exclusive. Sale will be closed at end block.
  uint public endBlock;
  // Minimum amount to raise for sale to be successful
  uint public minToRaise;
  // Total amount raised in sale
  uint public totalRaised;
  // Price for a single token wei
  uint public tokenPrice;
  // The address of the MDT Token
  Token public token;
  // Has the sale been finalized
  bool public saleFinalized = false;

  mapping (address => uint) public userBuys;

  function MerdetokenSale (uint _saleDuration, uint _minToRaise, uint _totalSupply)
  {
    startBlock = block.number;
    endBlock = startBlock + _saleDuration;
    minToRaise = _minToRaise;
    token = new Token(_totalSupply);
  }

  function buy(address _owner) internal
  saleOpen
  {
    userBuys[_owner] += msg.value;
    totalRaised += msg.value;
  }

  function () public payable {
    return buy(msg.sender);
  }

  function finalize() external
  saleClosed
  raisedMinimumAmount
  saleNotFinalised
  {
    uint totalSupply = token.totalSupply();
    tokenPrice = totalRaised / totalSupply;
    saleFinalized = true;
  }

  function claim() external
  saleFinalised
  {
    uint amount = userBuys[msg.sender] / tokenPrice;
    userBuys[msg.sender] = 0;
    assert(token.transfer(msg.sender, amount));
  }

  modifier saleOpen {
    assert(block.number >= startBlock);
    assert(block.number < endBlock);
    _;
  }

  modifier saleClosed {
    assert(block.number >= endBlock);
    _;
  }

  modifier raisedMinimumAmount {
    assert(totalRaised >= minToRaise);
    _;
  }

  modifier saleFinalised {
    assert(saleFinalized);
    _;
  }

  modifier saleNotFinalised {
    assert(!saleFinalized);
    _;
  }
}
