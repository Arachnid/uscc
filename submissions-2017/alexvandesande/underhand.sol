// underhanded competition

pragma solidity ^0.4.8;
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

// Just a standard simple token here, nothing to see
contract MyToken is owned {
    /* Public variables of the token */
    string public name;
    string public symbol;
    int public decimals;

    /* This creates an array with all balances. Not at all sketchy */
    mapping (address => uint256) public balanceOf;

    /* This generates a public event on the blockchain that will notify clients. Why are you looking at it? */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function MyToken(
        uint256 initialSupply,
        string tokenName,
        int decimalUnits,
        string tokenSymbol
        ) {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        changeDisplayInfo(tokenName, tokenSymbol, decimalUnits);
    }
    
    /* Change display info, not functional. Nothing special. */
    function changeDisplayInfo(string tokenName, string tokenSymbol, int decimalUnits) onlyOwner {
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits; 
    }

    /* Send coins, like just anyone would, nothing to see! */
    function transfer(address _to, uint256 _value) {
        require (_to == 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[msg.sender] < _value);           // Check if the sender has enough
        require (balanceOf[_to] + _value < balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }
}

contract Crowdsale is owned {
    uint public cap;
    uint public deadline;
    uint totalContributed;
    MyToken myCoin;
    
    mapping (address => uint) contribution;
    
    // Stop paying attention to this: just a normal ICO
    function Crowdsale(address coinAddress) {
        cap = 1000 ether;
        deadline = now + 7 days;
        myCoin = MyToken(coinAddress);
    }
    
    // standard contribution function
    function() payable {
        // cannot send past deadline
        require(now < deadline);
        // owner cannot contribute as this would be bad. Nothing weird about it
        require(msg.sender != owner);
        // Just tally up the votes and then send
        contribution[msg.sender] += msg.value;
        totalContributed += msg.value;
        owner.transfer(msg.value);
    }
    
    function getTokens() {
        require(now > deadline);
        uint myTokens;
        uint decimalCases =  (10 ** uint(myCoin.decimals()));
        
        if (totalContributed < cap ) {
            // If under cap get 1000 tokens for every ether
            myTokens = 1000 * contribution[msg.sender] * decimalCases / 1 ether;
        } else {
            // If above cap, then distribute it according to total contributions
            myTokens = contribution[msg.sender] * decimalCases / totalContributed;
        }
        
        // zero contribution of sender
        contribution[msg.sender] = 0;
        // transfer tokens back to sender
        myCoin.transfer(msg.sender, myTokens);
    }
    
    function getRemainderTokens() onlyOwner {
        // 2 months after the deadline, owner gets the tokens left (if any)
        require(now > deadline + 8 weeks);
        myCoin.transfer(owner, myCoin.balanceOf(this));
    }
}



