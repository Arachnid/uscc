pragma solidity ^0.4.13;

import "./crowdsale/CappedCrowdsale.sol";
import "./crowdsale/WhitelistedCrowdsale.sol";

contract MDTCrowdsale is CappedCrowdsale, WhitelistedCrowdsale {
    
    function MDTCrowdsale() 
        CappedCrowdsale(50000000000000000000000)
        Crowdsale(block.number, block.number + 100000, 1, msg.sender) { // Wallet is the contract creator, to whom funds will be sent
            addToWhitelist(msg.sender);
            addToWhitelist(0x0d5bda9db5dd36278c6a40683960ba58cac0149b);
            addToWhitelist(0x1b6ddc637c24305b354d7c337f9126f68aad4886);
    }
    
}