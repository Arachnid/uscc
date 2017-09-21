pragma solidity ^0.4.13;

contract Merdetoken {
    uint256 public totalSupply;
    address private ownerAddress;
    mapping(address => uint256) private balanceData;
    mapping (address => mapping (address => uint256)) private allowanceData;
    bool private hasFinishedMinting;

    function Merdetoken() {
        totalSupply = 0;
        ownerAddress = msg.sender;
        hasFinishedMinting = false;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        var sender = msg.sender;

        require((value == 0) || (allowanceData[sender][spender] == 0));

        allowanceData[sender][spender] = value;

        Approval(sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public constant returns (uint256) {
        return allowanceData[owner][spender];
    }

    function balanceOf(address addr) public constant returns (uint256)
    {
        return balanceData[addr];
    }

    function mint(address toAddress, uint256 value) public returns (bool) {
        var sender = msg.sender;

        require(sender == ownerAddress);
        require(hasFinishedMinting == false);

        assert((totalSupply+value) >= totalSupply);
        assert((balanceData[toAddress]+value) >= balanceData[toAddress]);

        totalSupply += value;
        balanceData[toAddress] += value;

        Mint(toAddress, value);
        return true;
    }

    function mintSetFinished() public returns (bool) {
        var sender = msg.sender;

        require(sender == ownerAddress);
        require(hasFinishedMinting == false);

        hasFinishedMinting = true;

        MintFinished();
        return true;
    }

    function transfer(address toAddress, uint256 value) public returns (bool)
    {
        var sender = msg.sender;

        assert(balanceData[sender] >= value);
        assert((balanceData[toAddress]+value) >= balanceData[toAddress]);

        balanceData[sender] -= value;
        balanceData[toAddress] += value;

        Transfer(sender, toAddress, value);
        return true;
    }

    function transferFrom(address fromAddress, address toAddress, uint256 value) public returns (bool) {
        var sender = msg.sender;
        var allowance = allowanceData[fromAddress][sender];

        assert(allowance >= value);
        assert(balanceData[fromAddress] >= value);
        assert((balanceData[toAddress]+value) >= balanceData[toAddress]);

        allowanceData[fromAddress][sender] = allowance - value;
        balanceData[fromAddress] -= value;
        balanceData[toAddress] += value;

        Transfer(fromAddress, toAddress, value);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed toAddress, uint256 value);
    event MintFinished();
    event Transfer(address indexed fromAddress, address indexed toAddress, uint256 value);
}

contract MerdetokenSale {
    address private ownerAddress;

    Merdetoken public token;

    uint256 constant SALE_SAFETY_CAP = 1000000 ether;
    uint256 constant VALUE_TO_TOKEN_RATE = 1;
    uint256 constant SALE_TOKENS_CAP = 100000 * VALUE_TO_TOKEN_RATE;
    uint256 constant MAX_USER_BUYIN = 100 ether;
    uint256 constant BIGBLOCKSIZE = 50;
    uint256 constant THRESHOLD_TIMEOUT = 4 days;  // If no threshold is set within 4 days users can refund their eth.
    enum InvestorState { NONE, PENDING, WIN, LOSS }

    struct BigBlock {
        uint256 index;
        uint256 total;
        mapping (address => uint256) userTotal;
    }

    address walletAddress;
    uint256 startTimeBlock;
    uint256 endTimeBlock;

    uint256 totalClaimed;
    uint256 totalRaised;
    uint256 totalInvestors;

    bool userRatingThresholdSet = false;
    int256 userRatingThreshold;

    address[] investorList;
    BigBlock[] bigBlocks;
    mapping (address => uint256) investorAmountData;
    mapping (address => uint256) investorTokenData;
    mapping (address => InvestorState) investorState;

    /**
    * The sale has an address for where funds are finally transferred.
    * The sale has start block and an end block.
    **/
    function MerdetokenSale(address addr, uint256 startBlock, uint256 endBlock) {
        require(addr != 0x0);
        require(startBlock >= block.number);
        require(endBlock >= startBlock);

        ownerAddress = msg.sender;
        token = new Merdetoken();
        walletAddress = addr;
        startTimeBlock = startBlock;
        endTimeBlock = endBlock;
        totalRaised = 0;
        totalInvestors = 0;
    }

    function () {
        buy(msg.sender);
    }

    /**
    * A user will send transaction with a value between 0.01 and 10 ether.
    * A user can send many transactions, but at most totalling 100 ether for the same address.
    * Users will be rewarded on how skilled they are in sending their transaction when
    * the volume is lower than average, as an incentive to not flood the system.
    *
    **/
    function buy(address toAddress) payable {
        address sender = msg.sender;
        uint256 value = msg.value;
        uint256 blockTimeNow = block.number;

        require(toAddress != 0x0);
        require(value >= 0.01 ether);
        require(value <= 10 ether);
        require((investorAmountData[toAddress] + value) <= MAX_USER_BUYIN);
        require(blockTimeNow >= startTimeBlock && blockTimeNow <= endTimeBlock);
        require((totalRaised + value) <= SALE_SAFETY_CAP);

        uint256 valueToToken = value * VALUE_TO_TOKEN_RATE;

        assert(value == 0 || (valueToToken / VALUE_TO_TOKEN_RATE) == value);
        assert((totalRaised + value) >= totalRaised);
        assert((investorAmountData[toAddress] + value) >= investorAmountData[toAddress]);
        assert((investorTokenData[toAddress] + valueToToken) >= investorTokenData[toAddress]);
        assert(investorList.length == totalInvestors);
        assert((totalInvestors+1) >= totalInvestors);

        investorList.push(toAddress);
        totalInvestors++;

        investorAmountData[toAddress] =+ value;
        investorTokenData[toAddress] += valueToToken;
        investorState[toAddress] = InvestorState.PENDING;

        totalRaised += value;

        uint256 bigBlockIndex = (block.number - startTimeBlock) / BIGBLOCKSIZE;
        assert(bigBlockIndex >= 0);
        if (bigBlocks.length == 0 ||
            bigBlocks[bigBlocks.length-1].index != bigBlockIndex ) {
            BigBlock memory big = BigBlock(0, 0);
            bigBlocks.push(big);
        }

        bigBlocks[bigBlocks.length-1].total++;
        bigBlocks[bigBlocks.length-1].userTotal[toAddress]++;

        Purchase(sender, toAddress, value, valueToToken);
    }

    /**
    * Threshold is calculated off-chain and must be set
    * by owner within four days after sale closes,
    * otherwise contract timeouts and users can reclaim
    * their ether and no tokens will be minted.
    **/
    function setThreshold(int256 threshold) public {
        uint256 blockTimeNow = block.number;
        var sender = msg.sender;

        require(blockTimeNow > endTimeBlock);
        require(sender == ownerAddress);

        // We allow for the threshold to set and set again,
        // if we for whatever reason got the calculations wrong.

        userRatingThresholdSet = true;
        userRatingThreshold = threshold;
    }

    /**
    * After sale window closes and threshold has been calculated and set,
    * each user must call this function to see if they won or lost.
    * If they won, they will then call claimTokens to get freshly minted Merde.
    * If they lost they must call claimEth to get a full refund of their ether.
    */
    function drawWinner() returns (string) {
        uint256 blockTimeNow = block.number;
        require((blockTimeNow > endTimeBlock));
        require(bigBlocks.length > 0);
        require(userRatingThresholdSet);
        require(investorState[msg.sender] == InvestorState.PENDING);

        int256 points = 0;
        points = rateUser(points, 0);

        DrawWinner(msg.sender);
        if(points  >= userRatingThreshold) {
            investorState[msg.sender] = InvestorState.WIN;
            return "WIN";
        } else {
            investorState[msg.sender] = InvestorState.LOSS;
            return "LOSS";
        }
    }

    /**
    * A winning user could claim freshly minted Merde Tokens.
    **/
    function claimTokens() returns(string) {
        var sender = msg.sender;
        uint256 blockTimeNow = block.number;

        require((blockTimeNow > endTimeBlock));
        require(investorState[sender] == InvestorState.WIN);
        require(investorTokenData[sender] > 0);

        uint256 amount = investorAmountData[sender];
        uint256 numTokens = investorTokenData[sender];

        if(token.totalSupply() + numTokens > SALE_TOKENS_CAP) {
            // This can only happen if we screwed up the threshold calculation.
            // We sadly will have to give user back ether instead of merder.
            investorState[sender] = InvestorState.LOSS;
            return "So sorry, out of tokens, please reclaim your ETH using claimEth()";
        }

        token.mint(sender, numTokens);
        investorAmountData[sender] = 0;
        investorTokenData[sender] = 0;
        totalClaimed += amount;
        ClaimTokens(sender, numTokens);
        return "Tokens on the way";
    }

    /**
    * A user who did not win will get a full refund of all ether.
    * Also if no threshold was set after four days from end of sale,
    * all ether can be refunded.
    */
    function claimEth() {
        var sender = msg.sender;
        uint256 blockTimeNow = block.number;

        require((blockTimeNow > endTimeBlock));

        // Users can reclaim their ether if they lost or if the contract has
        // timeouted waiting for owner to set threshold (owner died during sale).
        require(investorState[sender] == InvestorState.LOSS ||
                (userRatingThresholdSet == false &&
                 blockTimeNow > (endTimeBlock + THRESHOLD_TIMEOUT)));
        require(investorAmountData[sender] > 0);

        uint256 amount = investorAmountData[sender];
        investorAmountData[sender] = 0;
        investorTokenData[sender] = 0;
        totalClaimed += amount;
        sender.transfer(amount);
        ClaimEth(sender, amount);
    }

    /**
    * 30 days after token sale, owner can unconditionally
    * transfer the remaining funds to wallet.
    **/
    function transferFunds() {
        var sender = msg.sender;
        uint256 blockTimeNow = block.number;

        require(sender == ownerAddress);
        require(blockTimeNow > (endTimeBlock + 30 days));

        uint256 amount = this.balance;
        walletAddress.transfer(amount);
    }

    /**
    * For each time a user has participated in a big block which volume
    * is lower or on average of all big blocks volumes, the user gets one point,
    * if user participated in a "flooded" block user gets minus one point.
    * Users who get over the threshold will win and can mint tokens,
    * the others will lose and can claim all their ether to be refunded.
    **/
    function rateUser(int256 points, uint256 index) internal returns (int256) {
        if(index >= bigBlocks.length) {
            return points;
        }

        uint256 bigBlockTotal = bigBlocks[index].total;
        uint256 bigBlockUserTotal = bigBlocks[index].userTotal[msg.sender];
        uint256 bigBlocksTotalMean = totalInvestors / bigBlocks.length;

        if(bigBlockUserTotal > 0) {
            if(bigBlockTotal <= bigBlocksTotalMean) {
                points += 1;
            } else {
                points -= 1;
            }
        }

        return rateUser(points, index+1);
    }

    event ClaimEth(address indexed toAddress, uint256 amount);
    event ClaimTokens(address indexed toAddress, uint256 numTokens);
    event DrawWinner(address indexed toAddress);
    event Purchase(address indexed buyerAddress, address indexed toAddress, uint256 value, uint256 numTokens);
}
