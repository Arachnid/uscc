pragma solidity ^0.4.11;


import "zeppelin-solidity/contracts/token/MintableToken.sol";

contract MerdeToken is MintableToken {
  string public constant symbol = "MDT";
  string public constant name = "Merdetoken";
  uint256 public constant decimals = 18;
}
