pragma solidity ^0.4.11;

import './MerdeToken.sol';
import '../math/SafeMath.sol';

/**
 * @title Presale
 * @dev A simple crowdsale for whitelisted addresses.
 */
 contract Presale {
   /*
    *  Events
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /*
     *  Library
     */
   using SafeMath for uint256;

   /*
    *  Storage
    */
   MerdeToken public merdeToken;
   uint256 public startBlock;
   uint256 public endBlock;
   address public wallet;
   address public owner;
   uint256 public price;
   uint256 public weiRaised;
   mapping(address => bool) public whiteListed;

   enum Stages {
       SaleDeployed,
       SaleSetUp,
       SaleStarted,
       SaleEnded
   }

   /*
    *  Modifiers
    */
   modifier beforeStart() {
       require(block.number < startBlock);
       _;
   }

   modifier afterEnd() {
       require(block.number > endBlock);
       _;
   }

   modifier isOwner(){
     require(msg.sender == owner);
     _;
   }

   modifier isWhitelisted() {
     require(whiteListed[msg.sender]);
     _;
   }


   /*
    *  Public functions
    */
   /// @dev Contract constructor
   /// @param _wallet adddress Destination wallet
   /// @param _startBlock uint2556 Auction start block
   /// @param _endBlock uint256 Auction end block
   /// @param _price uint256 The price for token(in wei)
   function Presale(uint256 _startBlock, uint256 _endBlock, address _wallet, uint _price) {
     require(_startBlock >= block.number);
     require(_endBlock >= _startBlock);
     require(_price > 0);

     owner = msg.sender;
     startBlock = _startBlock;
     endBlock = _endBlock;
     price = _price;
     wallet = _wallet;
   }

   /// @dev fallback function can be used to buy tokens
   function () payable {
     buyTokens(msg.sender);
   }

   ///@dev low level token purchase function
   ///@param beneficiary address The beneficiary that will reieve tokens
   function buyTokens(address beneficiary) payable {
     require(beneficiary != 0x0);
     require(validPurchase());

     uint256 weiAmount = msg.value;

     // calculate token amount to be created
     uint256 tokens = weiAmount.mul(price);

     // update state
     weiRaised = weiRaised.add(weiAmount);

     merdeToken.mint(beneficiary, tokens);
     TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

   }

   /// @dev Checks if the purchase is validPurchase
   /// @return true if the transaction can buy tokens
   function validPurchase() internal constant returns (bool) {
     uint256 current = block.number;
     bool withinPeriod = current >= startBlock && current <= endBlock;
     bool nonZeroPurchase = msg.value != 0;
     return withinPeriod && nonZeroPurchase;
   }

   /// @dev Checks if cwordsale has ended
   /// @return true if crowdsale event has ended
   function hasEnded() public constant returns (bool) {
     return block.number > endBlock;
   }

   ///@dev Ends auction and foward funds to wallet
   function finalize()
     public
     isOwner
     afterEnd
   {
     selfdestruct(wallet);
   }
