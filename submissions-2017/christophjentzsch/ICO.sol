contract ICO {
    mapping(address => uint) magicBeans;
    uint totalSupply;
    address company;
    uint constant fundingGoal = 100000 ether;
    uint endOfFundingPeriod;

    modifier checkInvariant() {
        _;
        if (this.balance != totalSupply) throw;
    }

    function ICO(uint _endOfFundingPeriod ) {
        company = msg.sender;
        endOfFundingPeriod = _endOfFundingPeriod;
    }

    function() {throw;}

    function buyMagicBeans() payable checkInvariant() {
        if (now > endOfFundingPeriod) throw;
        magicBeans[msg.sender] += msg.value;
        totalSupply += msg.value;
    }

    function refund() checkInvariant() returns(bool) {
        uint tmpBeans = magicBeans[msg.sender];
        magicBeans[msg.sender] = 0;
        if (now > endOfFundingPeriod
            && totalSupply < fundingGoal  
            && msg.sender.send(tmpBeans)) {
                totalSupply -= tmpBeans;
                return true;
        }
        else
            magicBeans[msg.sender] = tmpBeans;
    }

    function fundTheProject() returns(bool) {
        if (now > endOfFundingPeriod + 42 days
            && company.send(this.balance))
                return true;
    }
}