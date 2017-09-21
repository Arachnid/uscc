pragma solidity ^0.4.11;

import "./MerdeToken.sol";

/**
 * @title DutchAuction
 * @dev Dutch Auction contract to sell Merde Tokens
 */
 contract DutchAuction {
     /*
      *  Events
      */
     event BidSubmission(address indexed sender, uint256 amount);

     /*
      *  Storage
      */
     MerdeToken public merdeToken;
     address public wallet;
     address public owner;
     uint public ceiling;
     uint public priceFactor;
     uint public startBlock;
     uint public endTime;
     uint public totalReceived;
     uint public finalPrice;
     mapping (address => uint) public bids;
     Stages public stage;

     enum Stages {
         AuctionDeployed,
         AuctionSetUp,
         AuctionStarted,
         AuctionEnded,
         TradingStarted
     }

     /*
      *  Modifiers
      */
     modifier atStage(Stages _stage) {
         if (stage != _stage)
             // Contract not in expected state
             revert();
         _;
     }

     modifier isOwner() {
         if (msg.sender != owner)
             // Only owner is allowed to proceed
             revert();
         _;
     }

     modifier isValidPayload(address receiver) {
         if (   msg.data.length != 4 && msg.data.length != 36
             || receiver == address(this)
             || receiver == address(merdeToken))
             // Payload length has to have correct length and receiver should not be dutch auction or gnosis token contract
             revert();
         _;
     }


     /*
      *  Public functions
      */
     /// @dev Contract constructor function sets owner
     /// @param _wallet address Destination wallet
     /// @param _ceiling uint Auction ceiling
     /// @param _priceFactor uint Auction price factor
     function DutchAuction(address _wallet, uint _ceiling, uint _priceFactor)
         public
     {
         if (_wallet == 0 || _ceiling == 0 || _priceFactor == 0)
             // Arguments are null
             revert();
         owner = msg.sender;
         wallet = _wallet;
         ceiling = _ceiling;
         priceFactor = _priceFactor;
         stage = Stages.AuctionDeployed;
     }

     /// @dev Setup function sets external contracts' addresses
     /// @param _merdeToken MerdeToken address
     function setup(MerdeToken _merdeToken)
         public
         isOwner
         atStage(Stages.AuctionDeployed)
     {
         if (address(_merdeToken) == 0)
             revert();
         merdeToken = _merdeToken;
         stage = Stages.AuctionSetUp;
     }

     /// @dev Starts auction and sets startBlock
     function startAuction()
         public
         isOwner
         atStage(Stages.AuctionSetUp)
     {
         stage = Stages.AuctionStarted;
         startBlock = block.number;
     }

     /// @dev Changes auction ceiling and start price factor before auction is started
     /// @param _ceiling uint Updated auction ceiling
     /// @param _priceFactor uint Updated start price factor
     function changeSettings(uint _ceiling, uint _priceFactor)
         public
         isOwner
         atStage(Stages.AuctionSetUp)
     {
         ceiling = _ceiling;
         priceFactor = _priceFactor;
     }

     /// @dev Calculates current token price
     /// @return Returns token price
     function calcCurrentTokenPrice()
         public
         returns (uint)
     {
         if (stage == Stages.AuctionEnded || stage == Stages.TradingStarted)
             return finalPrice;
         return calcTokenPrice();
     }

     /// @dev Returns correct stage, even if a function with timedTransitions modifier has not yet been called yet
     /// @return Returns current auction stage
     function updateStage()
         public
         isOwner
     {
         stage = Stages(uint(stage) + 1);
     }

     /*
      *  Fallback function
      */
     /// @dev If the auction is active, make a bid for msg.sender
     function()
         public
         isValidPayload(msg.sender)
     {
         if(stage != Stages.AuctionStarted)
           revert();
         bid(msg.sender);
     }

     /// @dev Allows to send a bid to the auction
     /// @param receiver address Bid will be assigned to this address if set
     function bid(address receiver)
         public
         payable
         isValidPayload(receiver)
         atStage(Stages.AuctionStarted)
         returns (uint amount)
     {

         receiver = msg.sender;
         amount = msg.value;

         uint maxWeiBasedOnTotalReceived = ceiling - totalReceived;
         // Only invest maximum possible amount
         if (amount > maxWeiBasedOnTotalReceived) {
             amount = maxWeiBasedOnTotalReceived;
             // Send change back to receiver address. In case of a ShapeShift bid the user receives the change back directly
             receiver.transfer(msg.value - amount);
         }
         bids[receiver] += amount;
         totalReceived = this.balance + amount;
         if (maxWeiBasedOnTotalReceived == amount)
             // When maxWei is equal to the big amount the auction is ended and finalizeAuction is triggered
             finalizeAuction();
         BidSubmission(receiver, amount);
     }

     /// @dev Claims tokens for bidder after auction
     /// @param receiver Tokens will be assigned to this address if set
     function claimTokens(address receiver)
         public
         isValidPayload(receiver)
         atStage(Stages.TradingStarted)
     {

         receiver = msg.sender;
         uint tokenCount = bids[receiver] * 10**18 / finalPrice;
         bids[receiver] = 0;
         merdeToken.transfer(receiver, tokenCount);
     }

     /// @notice The price function calculates the token price in the current block.
     /// @return Returns token price
     function calcTokenPrice()
         constant
         public
         returns (uint)
     {
         return priceFactor * 10**18 / (block.number - startBlock + 7500) + 1;
     }

     /// @dev Allow to start trading period
     function beginTradingPeriod()
         public
         isOwner
         atStage(Stages.AuctionEnded)
     {
         stage = Stages.TradingStarted;
     }

     /*
      *  Private functions
      */
     function finalizeAuction()
         private
     {
         stage = Stages.AuctionEnded;
         finalPrice = calcTokenPrice();
         endTime = now;
         // Crowdsale must be an authorized token minter
         merdeToken.mint(this, totalReceived / finalPrice + 1);
         wallet.transfer(this.balance);
     }
 }
