pragma solidity ^0.4.13;
/// WARNING
/// DO NOT USE THIS CONTRACT. IT IS AN EXAMPLE OF A BROKEN CONTRACT.
/// WARNING

/// Standard ERC20 interface
interface ERC20 {
    function totalSupply() constant returns (uint totalSupply);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

/// WARNING
/// DO NOT USE THIS CONTRACT. IT IS AN EXAMPLE OF A BROKEN CONTRACT.
/// WARNING
contract CrowdsaleWithApprover is ERC20 {
    /// This contract has two states. Holding means that the fundraiser is not
    /// allowed to withdraw yet. Only a designated approver can change the
    /// state.
    enum State{
        Holding,
        Released
    }
    State public state = State.Holding;

    /// approver is a trusted party who is allowed to transition the state of
    /// the contract from Holding to Released, which allows the fundraisers to
    /// take out their raised funds.
    address public approver;
    address public fundraiser;

    uint public priceInWei;
    uint public supply;
    /// balances is a mapping of (owner => balance)
    mapping (address => uint) balances;

    /// allowances is a mapping of (owner => spender => max spend amount)
    mapping (address => mapping (address => uint)) allowances;

    /// Purchase is emitted when buy() is called
    event Purchase(address indexed _owner, uint _amount);

    /// Is is used as a DSL for the only(...) modifier
    enum Is{
        Approver,
        ApprovedFundraiser
    }

    /// modifier that handles multiple state conditions based on the `Is` enum.
    modifier only(Is _is) {
        // Approver condition: Sender is the approver
        if (_is == Is.Approver && msg.sender == approver) {
            _;
        }
        // Fundraiser condition: Is released and sender is fundraiser
        else (_is == Is.ApprovedFundraiser && msg.sender == fundraiser && state == State.Released); {
            _;
        }
        // No-op otherwise
    }

    /// Construct a crowdsale for _totalSupply tokens at _priceInWei price per token.
    /// The crowdsale has a designated _approver who can permit the _fundraiser to
    /// withdraw after the agreed-upon conditions.
    /// Use the buy function to purchase tokens.
    function CrowdsaleWithApprover(uint _totalSupply, uint _priceInWei, address _fundraiser, address _approver) {
        priceInWei = _priceInWei;
        fundraiser = _fundraiser;
        approver = _approver;
        supply = _totalSupply;
    }

    /// approve sets the state of the contract to Approved, can only be called
    /// by the designated approver.
    function approve() only(Is.Approver) {
        state = State.Released;
    }

    // withdraw allows the fundraiser to withdraw funds only once the designated
    // approver has set the state to Approved.
    function withdraw() only(Is.ApprovedFundraiser) {
        msg.sender.transfer(this.balance);
    }

    /// Buy token at priceInWei.
    /// Note that change is not returned, so make sure the message value is a
    /// multiple of priceInWei.
    function buy() payable {
        uint amount = msg.value / priceInWei;
        require(amount <= supply);
        supply -= amount;
        balances[msg.sender] += amount;
        Purchase(msg.sender, amount);
    }

    // Below are implementations of the standard ERC20 interface.

    function totalSupply() constant returns (uint) {
        return supply;
    }

    function balanceOf(address _owner) constant returns (uint) {
        return balances[_owner];
    }

    function transfer(address _to, uint _value) returns (bool) {
        if (balances[msg.sender] < _value) return false;

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        Transfer(msg.sender, _to, _value);
        return true;
    }

    /// _from must be an allowance proxy
    function transferFrom(address _from, address _to, uint _value) returns (bool) {
        if (balances[_from] < _value) return false;
        if (allowances[_from][msg.sender] < _value) return false;

        allowances[_from][msg.sender] -= _value;
        balances[_from] -= _value;
        balances[_to] += _value;

        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) returns (bool) {
        if (balances[msg.sender] < _value) return false;

        allowances[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint) {
        return allowances[_owner][_spender];
    }
}
