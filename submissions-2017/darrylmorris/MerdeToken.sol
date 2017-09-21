/*-----------------------------------------------------------------------------\

                  MerdeTokenICO -  Generic Turkey ICO.
                  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Instant ICO!
Only on Etherium!
Ritten in Solidirty, the most secure programming langwich eva!

Just press "GoForLunch" and get up to $35,000,000 in 28 Days!

Then with draw 600 Either weakly from the very secure wallet over 4 years to
fund your "Development Team"!  Who knows, may be they can imagine thers a
"product" to develop.

With imagination, "The end's the limit!"

Testimonies
~~~~~~~~~~~
"Thanks to MerdeToken, my dog's finally got 5 legs!" - Prof Rufus UK
"I got $35m in 35 minutes. I call that a 'milaminute'!" - Betty FL
"Ja tok'n shit mun" - Tafari JAM
"Merdetokens, wee wee!" - Jacques FR

Fully written and auditored by expert professionals! 
This is what they had to say: 

"This white paper looks like it was bleached." - Jo
"WAT?" - Meggsy
"80 charater line limit? That's not even VGA." Jr
"You'll be hearing from my even smarter lawyer." - Jo Meggsy Jr

So, Go Go ICO!!!  You are GoForLaunch()!

Deployment Instructions
~~~~~~~~~~~~~~~~~~~~~~~
1. Deploy MerdeTokenICO
2. Funding is accepted from 7 days up to 35 days after deployment or until
   the 120,000 ether funding cap is reached.
3. The first allowable withdrawal will be 35 days after deployment on the
   condition the ICO was successful.
4. Holders can get a refund from a failed ICO 35 days after deployment.

License: Creative Commons Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0)
\-----------------------------------------------------------------------------*/


pragma solidity ^0.4.11;

import "./SafeMath.sol";

contract MerdeTokenICO is SafeMath {

/*---------------------------*/
/* ICO deployment Parameters */
/*---------------------------*/

    // Funding opens 7 days after deployment.
    uint public START_DATE = now + 7 days;
    
    // Funding period is up to 28 days after funding opens.
    uint public END_DATE = START_DATE + 28 days;
    
    // Ether cap is 120,000 ether
    uint public constant ETHER_CAP = 120000 ether;
    
    // Ether refund cap 12,000 ether
    uint public constant REFUND_CAP = 12000 ether;
    
    // 100 tokens are created per ether paid during funding
    uint public constant TOKENS_PER_ETH = 100;

/*-----------------*/
/* State Variables */
/*-----------------*/

// ERC20 State variables
    
    // Token name
    string public name = "Another MerderToken ICO";
    
    // Trading symbol
    string public symbol = "AMI";

    // Total number of tokens begins at 0.
    uint public totalSupply;
    
    // Fixed point for token.
    uint8 public constant decimals = 16;

    // Mapping of holder balances. Using public getter for simplicity
    mapping (address => uint) public balanceOf;
    
    // Mapping of spender allowances. Using public getter for simplicity
    mapping (address => mapping(address => uint)) public allowed;

// ICO State variables
    
    // Can withdraw 600 ether per week.
    uint public constant ETH_PER_WEEK = 600 ether;
    
    // Wallet owner. Is set at time of ICO creation.
    address public owner;

    // The total ether raised during funding
    uint public etherRaised;

    // Time of next withdrawal
    uint public nextWithdrawal;

/*--------*/
/* Events */
/*--------*/

    // When tokens are transferred
    event Transfer(address indexed _from, address indexed _to, uint _value);
    
    // When an allowance is change
    event Allowed (address indexed _holder, address indexed _spender,
        uint _value);
    
    // When tokens are creation.
    event TokensCreated(address indexed _holder, uint indexed _value);
    
    // When the owner is changed
    event Owner(address indexed _oldOwner, address indexed _newOwner);

    // When tokens are burned
    event Refunded(address indexed _holder, uint _value);
    
/*-----------*/
/* Modifiers */
/*-----------*/

    modifier onlyOwner 
    {
        require(msg.sender == owner);
        _;
    }

    // Funding is open between START_DATE and END_DATE or until ETHER_CAP is
    // reached
    modifier isFunding {
        require(now > START_DATE);
        require(now < END_DATE);
        require(add(msg.value, etherRaised) < ETHER_CAP);
        _;
    }
    
    // ICO is successful if the fund passed REFUND_CAP and END_DATE has passed
    modifier hasSucceeded {
        require(now >= END_DATE);
        require(etherRaised >= REFUND_CAP);
         _;
    }
    
    // Funding has failed if funds did not exceed REFUND_CAP cap by END_DATE 
    modifier hasFailed {
        require(now > END_DATE);
        require(etherRaised < REFUND_CAP);
        _;
    }
    
/*-----------*/
/* Functions */
/*-----------*/

    /// @dev Single click constructor - All MerdeTokens use same params
    function MerdeTokenICO()
    {
        owner = msg.sender;
        nextWithdrawal = END_DATE;
    }
    
    /// @dev The default function accepts payments only when funding is open.
    function() payable
        isFunding
    {
        require(msg.value > 0);
        
        // Calculate and assign tokens and increase supply
        uint tokens = mul(msg.value, TOKENS_PER_ETH);
        balanceOf[msg.sender] = add(balanceOf[msg.sender], tokens);
        totalSupply = add(totalSupply, tokens);
        
        // Track amount of ether raised
        etherRaised = add(etherRaised, msg.value);

        // Log token creation
        TokensCreated(msg.sender, tokens);
    }

/*-----------------*/
/* ERC20 Functions */
/*-----------------*/

    /// @notice Transfer `_value` tokens to `_to`
    /// @param _to an address of a possible token holder
    /// @param _value number of tokens to transfer
    function transfer(address _to, uint _value)
        hasSucceeded
        returns (bool)
    {
        // Validate _value
        require(_value != 0);
        require(_value <= balanceOf[msg.sender]);

        balanceOf[msg.sender] = sub(balanceOf[msg.sender], _value);
        balanceOf[_to]        = add(balanceOf[_to], _value);

        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /// @notice Transfer `_value` tokens from `_from` to `_to`
    /// @param _from an address of a possible token holder
    /// @param _to an address of a potential token holder
    /// @param _value number of tokens to transfer
    function transferFrom(address _from, address _to, uint _value)
        hasSucceeded
        returns (bool)
    {
        // Validate send _value
        require(_value <= allowed[_from][msg.sender]);
        require(_value <= balanceOf[_from]);
        require(_value != 0);

        // Process transfer
        allowed[_from][msg.sender] = sub(allowed[_from][msg.sender], _value);
        balanceOf[_from] = sub(balanceOf[_from], _value);
        balanceOf[_to]   = add(balanceOf[_to], _value);

        Transfer(_from, _to, _value);
        return true;
    }
    
    /// @notice Allows `spender` to send up to `value` tokens
    /// @param _spender a potential spender address
    /// @param _value a number of tokens
    function approve(address _spender, uint _value)
        hasSucceeded
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        Allowed(msg.sender, _spender, _value);
        return true;
    }

/*---------------*/
/* ICO Functions */
/*---------------*/

    // Only owner can change wallet owner
    function changeOwner(address _owner)
        onlyOwner
        returns (bool)
    {
        Owner(owner, _owner);
        owner = _owner;
        return true;
    }

    /// @dev The ICO can be canceled by the owner before it starts funding
    function cancel()
        onlyOwner
    {
        require(now < START_DATE);
        selfdestruct(0x0);
    }
    
    /// @dev Refunds can be given from a failed ICO after 5 weeks from
    /// deployment
    function refund()
        hasFailed
        returns (bool)
    {
        uint tokens = balanceOf[msg.sender];
        require(tokens > 0);
        
        uint value = tokens / TOKENS_PER_ETH;
        totalSupply = sub(totalSupply, tokens);
        delete balanceOf[msg.sender];
        Refunded(msg.sender, value);
        
        // Transfer refund from fundWallet to holder
        msg.sender.transfer(value);
        return true;
    }

    /// @dev Withdrawal limited to 600eth per week. Only owner can withdraw
    /// funds.
    function weeklyWithdraw()
        onlyOwner
        hasSucceeded
        returns (bool)
    {
        require(now > nextWithdrawal);

        // Advance withdrawal date by 7 days
        nextWithdrawal = add(nextWithdrawal, 7 days);
        
        // Last withdrawl may be < 600eth.
        uint value = this.balance > ETH_PER_WEEK ? ETH_PER_WEEK : this.balance;
        
        // Send to funds to owner
        owner.transfer(value);
        return true;
    }
}
