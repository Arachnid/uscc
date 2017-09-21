import "./StandardToken.sol";

contract MDTToken is StandardToken {

    string constant name = "Merdetoken";
    string constant symbol = "MDT";

    address public owner;
    address[] public investors;
    address public burnAddress = 0x000000000000000000000000000000000000dead;
    mapping(address => uint256) investorIndex;
    mapping(address => bool) public withdrawn;
    bool public isFinalized;
    uint256 public constant payoutPercent = 20;
    uint256 public constant mdtFund = (10 ** 6);
    // Assuming 16s-ish block times
    uint256 public constant withdrawWithoutPenaltyDate = 1 years / 16 seconds;
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyOwnerOrInvestor() {
        if (msg.sender != owner) {
            require(investorIndex[msg.sender] != 0);
        }
        _;
    }

    function MDTToken(address[] _investors)
    {
      isFinalized = false;
      // Assuming 16s-ish block times
      fundingStartBlock = block.number;
      fundingEndBlock = fundingStartBlock + (30 days / 16 seconds);
      owner = msg.sender;
      investors.push(owner);
      for (uint i = 1; i < _investors.length + 1; i++) {
        investorIndex[_investors[i-1]] = i;
        investors.push(_investors[i-1]);
      }
    }

    function createTokens() payable external {
      require(!isFinalized);
      require(block.number > fundingStartBlock);
      require(block.number < fundingEndBlock);
      require(msg.value > 0);

      balances[msg.sender] += msg.value;
      burnAddress.transfer(msg.value);
    }

    function finalize() onlyOwner external {
      require(!isFinalized);
      require(block.number >= fundingEndBlock);
      isFinalized = true;
    }

    function withdrawMDT() onlyOwnerOrInvestor {
        require(isFinalized);
        require(!withdrawn[msg.sender]);

        withdrawn[msg.sender] = true;
        // owner has to withdraw before investors can
        if (msg.sender == owner) {
            // penalty for withdrawing early
            uint256 penalty = calculatePenalty();
            balances[msg.sender] += (((payoutPercent - penalty) * mdtFund) / 100);
        } else {
          require(withdrawn[owner]);
          // Investors get 80% / however many investors there are
          uint256 payoutPercent = 80 / investors.length;
          for (var i = 1; i < investors.length; i++) {
              balances[investors[i]] += ((payoutPercent * mdtFund) / 100);
          }
        }
    }
    
    // Calculate the penalty for early withdrawal depending on how
    // far into the 1 year withdraw date we are
    function calculatePenalty() internal returns (uint256) {
        uint256 blocksElapsed = block.number - fundingEndBlock;
        uint256 penalty = payoutPercent - ((blocksElapsed * payoutPercent) / withdrawWithoutPenaltyDate);
        // Ensure penalty is at most payoutPercent - 1
        return penalty == payoutPercent ? payoutPercent - 1 : penalty;
    }

}
