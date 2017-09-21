pragma solidity ^0.4.11;


import '../math/SafeMath.sol';

/**
 * @title MerdeToken token
 * @dev Simple ERC20 Token example, with mintable token creation
 */

 contract MerdeToken {
   /*
    *  Events
    */
   event Mint(address indexed to, uint256 amount);
   event MintFinished();
   event MintRequest(address indexed requester, address indexed to, uint256 amount);
   event Transfer(address indexed from, address indexed to, uint256 value);

   /*
    *  Library
    */
   using SafeMath for uint256;

   /*
    *  Storage
    */
   address public owner;
   bool public mintingFinished = false;
   uint256 public totalSupply;
   uint256 public decimals = 18;
   string public name = "MerdeToken";
   string public symbol = "MDT";
   mapping(address => bool) allowedMinters;
   mapping(address => uint256) balances;

   /*
    *  Modifiers
    */
   modifier canMint() {
     require(!mintingFinished);
     _;
   }

   modifier isOwner() {
       if (msg.sender != owner)
           // Only owner is allowed to proceed
           revert();
       _;
   }

   modifier isMinter() {
         // Only minters are allowed to proceed
     require(allowedMinters[msg.sender]);
     _;
   }

   /*
    *  Public Functions
    */
    function MerdeToken() {
      owner = msg.sender;
    }

    function addMinter(address minter)
         public
         isOwner
    {
         allowedMinters[minter] = true;
    }

   /**
   * @dev transfer token for a specified address
   * @param _to address The address to transfer to.
   * @param _value uint256 The amount to be transferred.
   */
   function transfer(address _to, uint256 _value)
       public
       returns (bool)
   {
       balances[msg.sender] = balances[msg.sender].sub(_value);
       balances[_to] = balances[_to].add(_value);
       Transfer(msg.sender, _to, _value);
       return true;
   }

   /**
   * @dev Gets the balance of the specified address.
   * @param _owner address The address to query the the balance of.
   * @return An uint256 representing the amount owned by the passed address.
   */
   function balanceOf(address _owner)
       public
       constant
       returns (uint256 balance)
   {
       return balances[_owner];
   }

   /**
    * @dev Function to mint tokens
    * @param _to address The address that will recieve the minted tokens.
    * @param _amount uint256 The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
   function mint(address _to, uint256 _amount)
       isMinter
       canMint
       public
       returns (bool)
   {
       totalSupply = totalSupply.add(_amount);
       balances[_to] = balances[_to].add(_amount);
       Mint(_to, _amount);
       return true;
   }

   /**
    * @dev Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
   function finishMinting()
       isOwner
       public
       returns (bool)
   {
     mintingFinished = true;
     MintFinished();
     return true;
   }

   function requestMint(address _to, uint amount)
       public
   {
       MintRequest(msg.sender, _to, amount);
   }

 }
