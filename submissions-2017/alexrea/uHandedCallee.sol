pragma solidity ^0.4.11;

contract uHandedCallee{
    address delegatecallTarget;
    address owner;
    address controller;
    uint totalNumberOfTokens;
    bool tokenSaleActive;
    uint lastStipendTime;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    //Standard implementations of transfer, transferFrom and approve, taken from
    // https://github.com/ConsenSys/Tokens/blob/master/Token_Contracts/contracts/StandardToken.sol

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    // By having this function, note the controller has control over the stipend rate - this could change,
    // but we don't want it to encourage it, hence not having it in a state variable and a function to
    // change. Changing it requires deploying a new uHandedCallee contract and changing delegatecallTarget.
    // This should be a very rare event, as bugs in a new uHandedCallee may result in the loss of token balance
    // for users.

    // We believe this strikes a balance between the controller ultimately being in control, but also being
    // disincentivised to mess the owner around.

    function withdraw_to_0xefcf026(uint timeSinceLastStipend){
        uint256 stipendRate = uint256(10 ether) / uint256(1 weeks);
        uint256 amount = timeSinceLastStipend * stipendRate;
        // Don't try and send more than we have - presumably, now, we're at the end of
        // the stipend.
        if (this.balance < amount){
            amount = this.balance;
        }
        owner.send(amount);
    }

}
