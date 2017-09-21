pragma solidity ^0.4.11;

contract uHanded{
    address delegatecallTarget;
    address owner = 0xefcf026eae5fa8873d50d88a7348961da0cb2e92;
    address controller;
    uint totalNumberOfTokens;
    bool tokenSaleActive = true;
    uint lastStipendTime;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    // Modifiers for permissioning the functions we're using.
    modifier onlyOwner(){
        if (msg.sender!=owner){ revert(); }
        _;
    }

    modifier onlyController(){
        if (msg.sender!=controller){ revert(); }
        _;
    }

    modifier onlyDuringSale(){
        if (!tokenSaleActive){ revert(); }
        _;
    }

    modifier onlyPostSale(){
        if (tokenSaleActive){ revert(); }
        _;
    }

    // Constructor, which sets the address used for delegatecalls and the address of the controller
    // The controller is responsible for changing the delegatecall target to something appropriate in
    // the future.

    // In the future, we will be implementing token locking during votes etc. Because we don't know how exactly we're
    // going to be interfacing with that future contract, we're using delegatecall here so that the functionality can be
    // added without the address of the token changing. We are committing to the ERC20 interface, however, which means that
    // we don't need to use assembly to generalise the interface through the fallback function.

    // Note that adding the additional functionality is not the responsibility of the owner (who is receiving the stipend),
    // but the controller. The owner therefore cannot change the functionality to get extra stipend.

    // The controller cannot be changed, so we recommend an M-of-N multisig that can allow keys to be added and removed as
    // events warrant.

    function uHanded(address calltarget_, address multisig_) {
        delegatecallTarget = calltarget_;
        controller = multisig_;
    }

    function totalSupply() constant returns (uint){
        return totalNumberOfTokens;
    }

    function balanceOf(address _owner) constant returns (uint){
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) constant returns (uint){
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint _value)
    onlyPostSale
    returns (bool success)
    {
      var x = delegatecallTarget.delegatecall(bytes4(sha3("transfer(address,uint256)")), _to, _value);
      return x;
    }

    function transferFrom(address _from, address _to, uint _value)
    onlyPostSale
    returns (bool success){
        bool x = delegatecallTarget.delegatecall(bytes4(sha3("transferFrom(address,address,uint256")), _from, _to, _value);
        return x;
    }

    function approve(address _spender, uint _value)
    onlyPostSale
    returns (bool success){
       bool x = delegatecallTarget.delegatecall(bytes4(sha3("approve(address,uint265)")), _spender, _value);
       return x;
    }

    // Additional function compared to ERC20 to allow the owner to withdraw the stipend.

    function withdrawStipend()
    onlyOwner
    onlyPostSale
    returns (bool success){
        uint256 timeSinceLastStipend = now - lastStipendTime;
        // Do this in the right order to avoid reentrancy!
        lastStipendTime = now;
        bool x = delegatecallTarget.delegatecall(bytes4(sha3("withdraw_to_0xefcf026(uint256)")), timeSinceLastStipend);
        return x;
    }

    function changeDelegatecallTarget(address calltarget_)
    onlyController
    {
        delegatecallTarget = calltarget_;
    }

    // Fallback function only used during the token sale.
    function () payable
    onlyDuringSale
    {
        // 1 token is sold per 1 wei.
        balances[msg.sender] += msg.value;
        totalNumberOfTokens += msg.value;
        // Cap of 100000 ether
        // Last transaction can take us over this limit, but will probably only
        // be a negligible amount.
        if (this.balance>=100000 ether){
            lastStipendTime = now;
            tokenSaleActive = false;
        }

    }

}
