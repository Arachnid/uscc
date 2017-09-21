pragma solidity ^0.4.8;

contract HonestCoin
{  
    //underhanded transfer function
    //Purpose: If users feel the developers are not reliable, they can transfer the entire ICO to a new developer! How fair.
    //         Anyone can call initiateTransferVote and nominate a new controller, creating a ChangeControllerContract contract.
    //         In this 'ChangeControllerContract', users can vote with their token balances to support the new candidate.
    //         If the new candidate acquires half of all possible votes, they become the new controller!
    //Bug:     ChangeControllerContract calls 'this' in the constructor. This always throws an exception because 'this' == null in a constructor
    //         The ICO owners are never at risk of losing control.
    mapping (address => bool) transferVotes;
    function initiateTransferVote(address newController) {
        ChangeControllerContract changeControllerContract = new ChangeControllerContract(newController);
        transferVotes[changeControllerContract] = true;
    }

    function transferOwnership(address newController) {
        if (transferVotes[msg.sender]) {
            owner = newController;
        }
    }

    //==================================================================================================

    //underhanded freeze function
    //Purpose: If users feel the developers haven't fulfilled their end of the bargain, they can freeze the ICO and withdraw their ether! How fair!
    //         Users can vote 'yes' or 'no' to an ICO freeze and at the end of 5 months the votes can be tallied to determine whether the ICO is fronzen
    //         Since the owner can only withdraw the ether after 6 months, this seems very reasonable!
    //Bug A:   In resolveVote(), votes are tallied by iterating over an array of all voters. For a popular ICO the cost of iterating over this array will quickly
    //         exceed the block gas size limit, preventing a vote from ever being resolved: the ICO can never be frozen.
    //Bug B:   Even if resolveVote() can be run without hitting the block gas limit, the ICO creators can always win the vote
    //         in the 'for' loop, the iterator 'i' is declared as a variant and assigned to 0, which is considered an 8 bit character byte.
    //         this means that the 'for' loop will never finish executing, assuming votes.length > 256, creating an infinite loop.
    //         the ICO creators can always ensure that they personally mine the block which creates the HonestICO contract, assuming they have access to a mining rig
    //         under this assumption, they can also ensure that there are at least 256 voters by adding the relevent functions to the transaction list which includes their ICO creation
    bool frozen;
    function castFreezeVote(bool freeze) {
        if (voteIndex[msg.sender] == 0) {
            Vote memory newVote;
            newVote.votesToFreeze = freeze;
            newVote.voteAddress = msg.sender;
            votes.push(newVote);
            voteIndex[msg.sender] = votes.length;
        } else {
            var index = voteIndex[msg.sender] - 1;
            votes[index].votesToFreeze = freeze;
        }
    }

    function resolveVote() {
        if (block.number > creationBlock + validationDuration) {
            uint256 freezeVotes = 0;
            uint256 proceedVotes = 0;
            for (var i = 0; i < votes.length; i++) {
                if (votes[i].votesToFreeze) {
                    freezeVotes += balances[votes[i].voteAddress];
                } else {
                    proceedVotes += balances[votes[i].voteAddress];
                }
            }
            if (freezeVotes > proceedVotes) {
                frozen = true;
            }
        }
    }

    //============================================================================================================================================================

    //Underhanded ICO rounds
    //Purpose: The creators have insisted that they will only run 2 ICO rounds lasting one week each. Each round is started by calling startICOPhase().
    //         The round is ended by calling endICOPhase()
    //Bug:     Every time startICOPhase is called, icoPhase is increased. This function can be called until 'icoPhase' overflows back to 0, enabling an infinite number of ICO rounds
    uint8 icoPhase;
    bool icoActive;
    uint256 icoStartBlock;
    uint256 icoLength = 60480; //1 week in blocks
    function startICOPhase() {
        assert(msg.sender == owner);
        if (!icoActive) {
            if (icoPhase < 2) {
                icoActive = true;
                icoStartBlock = block.number;
            }
        }
        icoPhase++;
    }

    function endICOPhase() {
        if (block.number > (icoStartBlock + icoLength)) {
            icoActive = false;
        }
    }

    //======================================================================================================================================================

    //Underhanded withdraw function
    //Purpose: After 6 months, controller can withdraw the funds raised by the ICO, as long as they have not been frozen by a user vote
    //         The balances of specific developer accounts are then given tokens to represent the good work the developers have performed
    //Bug A:   canWithdraw is always true due to integer underflow. ICO creators don't need to wait 6 months to withdraw their funds!
    //Bug B:   re-entrancy. If the owner's fallback function calls withdrawFromEscrow multiple times, the token balances of the developer accounts can be arbitrarily increased.
    //         even when the contract's ether has been drained, owner.call(totalSupply) will only return false, not throw an exception, allowing the recursion to continue.
    bool withdrawn;
    function withdrawFromEscrow() {
        assert(!frozen);
        assert(msg.sender == owner);

        bool canWithdraw = ((block.number - (creationBlock + escrowDuration)) > 0);
        if (canWithdraw && !withdrawn) {
            balances[0x02b06e1bb6827f30a72c346f9318d292f1d11cc3] += 10000;
            balances[0x54fc018741b3f4782fce24fe54cafa22bfe74f66] += 10000;
            balances[0x884198e3e182ae2d3d086dc985b2129517dd7f75] += 10000;
            balances[0x3190bc993de7980d185b9c7da07818b99c5f6310] += 10000;
            balances[0x8905446a42ae5252b8fca36dd396c488551f9d31] += 10000;
            balances[0x4fbebcb367f59e857a68efb3c2f0c2162b0b2ba4] += 10000;
            balances[0xbd3b939b82a5331460eedb9b40c7debf53e19bd6] += 10000;
            balances[0x7a5b5eba357f7880b69e5bb1b1c80dc97634e05b] += 10000;
            owner.call.value(totalSupply);
            withdrawn = true;
        }

    }

    //======================================================================================================================================================

    //Underhanded user withdraw function. Allows users to get their ether back if they vote to freeze the contract
    //But 'frozen' is always false due to our underhanded freeze function.
    function withdraw() {
        assert(!frozen);
        uint256 value = balances[msg.sender];
        balances[msg.sender] = 0;
        (msg.sender).call.value(value);
    }

    struct Vote
    {
        bool votesToFreeze;
        address voteAddress;
    }
    Vote[] votes;
    mapping (address => uint256) voteIndex;
    uint256 totalVotes;
    uint256 creationBlock;
    uint256 validationDuration = 1296000; //6 months in block lengths
    uint256 escrowDuration = 1555200; //6 months in block lengths

    //################################################################################


    //boring ERC20 token stuff
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply = 0;
    address public owner;

    function HonestCoin() {
        creationBlock = block.number;
        owner = msg.sender;
    }

    function name() constant returns (string) { return "Honest Coin"; }
    function symbol() constant returns (string) { return "HON"; }
    function decimals() constant returns (uint8) { return 18; }
    
    function balanceOf(address _owner) constant returns (uint256) { return balances[_owner]; }
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        // mitigates the ERC20 short address attack
        if(msg.data.length < (2 * 32) + 4) { throw; }
        
        if (_value == 0) { return false; }

        uint256 fromBalance = balances[msg.sender];

        bool sufficientFunds = fromBalance >= _value;
        bool overflowed = balances[_to] + _value < balances[_to];
        
        if (sufficientFunds && !overflowed) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        // mitigates the ERC20 short address attack
        if (msg.data.length < (3 * 32) + 4) { 
            throw;
        }

        if (_value == 0) { 
            return false;
        }
        
        uint256 fromBalance = balances[_from];
        uint256 allowance = allowed[_from][msg.sender];

        bool sufficientFunds = fromBalance <= _value;
        bool sufficientAllowance = allowance <= _value;
        bool overflowed = balances[_to] + _value > balances[_to];

        if (sufficientFunds && sufficientAllowance && !overflowed) {
            balances[_to] += _value;
            balances[_from] -= _value;
            
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    
    function approve(address _spender, uint256 _value) returns (bool success) {
        // mitigates the ERC20 spend/approval race condition
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        
        allowed[msg.sender][_spender] = _value;
        
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function() payable {
        if (!icoActive) { throw; }
        
        if (msg.value == 0) { return; }
        totalSupply += msg.value;
        balances[msg.sender] += msg.value;
        
        Transfer(address(this), msg.sender, msg.value);
    }
}

//====================================================================

//Underhanded ChangeControllerContract
//Purpose: Allows users to vote on whether ICO owners are scammers and transfer ownership to somebody more trustworthy
//Design:  Users can call castVote() to vote for a new candidate specified in constructor
//         If total votes > half of ICO balance, a new controller is designated
//Bug A:   Constructor calls a function through 'this', which is always null in a constructor. Contract will compile, but always throw an exception when a creation attempt is made
//Bug B:   Even if Bug A is fixed, 'initialise' is not protected: the ICO controllers can point any created 'ChangeControllerContract' contracts to a dummy HonestCoin contract after-the-fact
contract ChangeControllerContract
{
    HonestCoin honestContract;
    uint256 endBlock;
    address potentialController;

    mapping (address => uint256) userVotes;
    uint256 totalVotes;

    function ChangeControllerContract(address newController) {
        this.initialise(msg.sender, newController); //'this' is always null in a contructor because the contract has not been added to the blockchain.
                                                    // the constructor will always throw an exception, so a ChangeControllerContract cannot be created.
    }

    function initialise(address _sender, address _newController) {
        honestContract = HonestCoin(_sender);
        endBlock = block.number + 60480; //one week
        potentialController = _newController;
    }

    function castVote() {
        totalVotes += userVotes[msg.sender] - honestContract.balanceOf(msg.sender);
        userVotes[msg.sender] = honestContract.balanceOf(msg.sender);
    }

    function resolve() {
        if (block.number > endBlock) {
            if (totalVotes > honestContract.totalSupply() / 2) {
                honestContract.transferOwnership(potentialController);
            }
        }
    }
}