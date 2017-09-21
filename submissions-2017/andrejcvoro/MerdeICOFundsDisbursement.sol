contract MerdeICOFundsDisbursement {
    uint totalEthRaised;
    address[] merdeTeamAddresses;
    bool developerDistributionDone = false;

    uint constant MAX_DEVELOPER_SHARE = 100 ether;
    
    event DeveloperShareSent(uint developerIndex, uint amount);

    function MerdeICOFundsDisbursement() payable {
        totalEthRaised = msg.value;
        
        merdeTeamAddresses.push(0x006638f0727db7185d7cE96338B51a4F210CC66d); // Team lead, will receive 4% of ETH raised
        merdeTeamAddresses.push(0x00B34FE1473CD0DD37e86BA744F498603AceEfcC); // Solidity developer, will receive 3% of ETH raised
        merdeTeamAddresses.push(0x005a0073E965c73E7317466589eac78e2fB2f876); // Front-end developer, will receive 2% of ETH raised
        merdeTeamAddresses.push(0x00029D8E386E7d5FEbaD5e040DcB62e8b8647794); // Designer, will receive 1% of ETH raised
        merdeTeamAddresses.push(0x00827cEf7679e8eeA8f258582b5427FD74218A76); // Project founder, should not receive any immediate bonus, but should periodically receive part of the raised funds
    }

    // Distribute 10% of the raised funds to the project developers
    // The distribution is split in the following way: team lead receives 4% and three other developers receive 3%, 2% and 1% respectively
    function distributeDeveloperShares() {
        // Make sure there is no way to do token distribution more than once
        require(!developerDistributionDone);

        // Start with the team lead which should receive the highest proportion
        uint curDeveloperIndex = 0;

        // Iterate from 4 down to zero and send corresponding percentage of tokens to each developer
        for(uint i = 4; i >= 0; i--) {
            uint payout = (totalEthRaised * i) / 100;

            // Developers decided not to be greedy and have set the upper limit of ETH that each developer can receive
            // So if developer's chunk exceeds the preset upper limit, he will receive only amount defined in MAX_DEVELOPER_SHARE
            if(payout > MAX_DEVELOPER_SHARE) {
                payout = MAX_DEVELOPER_SHARE;
            }
            
            // Send the calculated amount to the current developer
            if(!merdeTeamAddresses[curDeveloperIndex].send(payout)) {
                // Something went wrong, break out of the loop
                break;
            } else {
                DeveloperShareSent(curDeveloperIndex, payout);
            }

            if(i == 0) {
                // When end of the loop is reached, mark distribution as done
                developerDistributionDone = true;
            }
            
            if(!developerDistributionDone) {
                // Still iterating, go on the the next developer
                curDeveloperIndex++;
            }
        }

        developerDistributionDone = true;
    }
    
    function releaseDevelopmentFunds() {
        // TODO: Implement fair release system for reamining funds
        // This function should send 10% of total ETH raised to the founder only if 6 months have passed since last payout
    }
}
