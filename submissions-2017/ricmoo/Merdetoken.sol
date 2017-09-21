/**
 *  Merdetoken
 *
 *  See: https://theethereum.wiki/w/index.php/ERC20_Token_Standard
 *
 *  This ICO allows participants to send ether to this contract in exchange
 *  for MDT tokens during the presale period (4 weeks).
 *
 *  Once the presale period is over, no addition tokens may be created and the owner is
 *  able to withdraw the funds in according to a schedule which increases over time:
 *    - week 1: 1 ether
 *    - week 2: 2 ether
 *    - week 3: 4 ether
 *    - week 4: 8 ether
 *  ...and so on. This way as the project grows and further funds are required, more can
 *  be withdrawn, however, by deferring the funding, the owner cannot just cash out and
 *  skip town.
 *
 *  An entry for a sinister contract...
 *
 *  Content Info:
 *    http://u.solidity.cc/?t=1&cn=ZmxleGlibGVfcmVjc18y&iid=41e0d6e3f8114ddc86b2bd023e624f01&uid=869384457991671808&nid=244+272699400
 *
 *
 *  Licensed under both:
 *    - MIT License
 *    - Creative Commons Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0)
 *
 *  Author information will be added once the contest has ended.
 */


// Not part of the exploit... Just shutting up compiler warnings...
pragma solidity ^0.4.10;


contract Merdetoken {

    // ERC-20 constants
    string public constant name = "Merdetoken";
    string public constant symbol = "MDT";
    uint8 public constant decimals = 18;

    // The ICO owner
    address owner;

    // The token balance for each member
    mapping (address => uint256) balances;

    // Allowances for each member
    mapping(address => mapping (address => uint256)) allowed;

    // The total supply of these tokens
    uint256 _totalSupply;

    // The date that the presale ends and the token can be traded
    uint256 activationDate;

    // The last time the owner issued withdraw(uint256)
    uint256 lastWithdrawDate;

    /**
     *  constructor(uint256)
     *
     *  Create a new instance of the Merdetoken, with a given presale
     *  duration.
     */
    function Merdetoken(uint256 duration) payable {

        // Set the ICO owner
        owner = msg.sender;

        // The owner can buy their own tokens with an endowment (if desired)
        balances[msg.sender] = msg.value;
        _totalSupply = msg.value;

        // Set the ICO presale end date
        activationDate = now + duration;
    }

    /**
     *  withdraw(uint256)
     *
     *  After the presale, the ICO owner may withdraw Ether from the contract
     *  on a deferred schedule; once per week, the amount doubling each week.
     */
    function withdraw(uint256 amount) {

        // Cannot withdraw during the presale
        if (now < activationDate) { throw; }

        // Only the owner may withdraw funds
        if (msg.sender != owner) { throw; }

        // Only allow sane values to be sent
        if (amount == 0 || amount > this.balance) { throw; }

        // Can only withdraw once per week
        if (now < lastWithdrawDate + (1 weeks)) { throw; }
        lastWithdrawDate = now;

        // Deferred withdraw schedule; may only withdraw 1 more ether than has ever
        // been withdrawn. See top decription for schedule.
        uint256 maxAmount = (_totalSupply - this.balance + (1 ether));

        // Cannot withdraw more than the maximum allowed by schedule
        if (amount > maxAmount) { throw; }

        // Send the funds
        if (!owner.send(amount)) { throw; }
    }

    /**
     *  fallback function
     *
     *  Exchange Ether for MDT tokens. This may not be called once the presale has ended.
     */
    function () payable {

        // Can only buy tokens during the presale
        if (now >= activationDate) { throw; }

        // Give out the tokens
        balances[msg.sender] += msg.value;
        _totalSupply += msg.value;
    }


    /**
     *   ERC-20 token; nothing sinister below here (if there is, it wasn't intended)
     *   Mostly just copy and pasted from the de facto existing implmentation; changes marked
     */

     function totalSupply() constant returns (uint totalSupply) {
         return _totalSupply;
     }

    function balanceOf(address _owner) constant returns (uint256 balance) {
         return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) returns (bool success) {

        // Cannot transfer tokens during the presale
        if (now < activationDate) { return false; }

        if (balances[msg.sender] < _amount || _amount == 0) { return false; }

        balances[msg.sender] -= _amount;
        balances[_to] += _amount;

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {

        // Cannot transfer tokens during the presale
        if (now < activationDate) { return false; }

        if (allowed[_from][msg.sender] < _amount || balances[_from] < _amount || _amount == 0) {
            return false;
        }

        balances[_from] -= _amount;
        allowed[_from][msg.sender] -= _amount;
        balances[_to] += _amount;

        return true;
    }

    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        return true;
    }
}
