/**

Knights of the Round Table investment group

1. KRT is a DAO, ruled by the 15 members of the round table. 
2. The 15 members decide on the use of the funds, each entitled to 1 vote. 

The ICO is where people can buy a seat at the table. There are 14 seats for purchase (seat 0 is taken), 
and each 'prospect' can bid on a seat. 

* Each seat is individually auctioned, 
* all bids immediately becomes part of KRT funds. 

For example: 

1. John bids 5 ether on seat 5. It is vacant, so John gets seat 5. 
2. Then Joe bids 6 ether for seat 5, and now Joe holds seat 5. 
3. The KRT now has 11 ether in auction portfolio. 
4. When auction-phase is over, a fraction[1] is earmarked for the creator as honorarium.


[1] Creator gets a fraction of the bids. So each bid yields 100 wei to the creator. In the example, 
    creator would get 200 wei, and remaining (11 ether - 200 wei) would be left for the to war-chest, for future 
    enterprises. 

To facilitate easier bidding, it's possible to bid on several seats. The bidder then specifies the seats he's 
interested in.

**/
pragma solidity ^0.4.11;

// Standardized bidding interface
contract BiddingInterface{
	function bid(address bidder, uint[] seats, uint[] bids) public payable;
}

contract RoundTable is BiddingInterface{

	/**
	This is the ICO contract. Other contracts ruling the vault implements the actual
	voting/DAO-logic.
	This contract only auctions all seats 1-14.
	Seat 0 is held by the creator, who get's a _tiny_ portion of each bid 
	**/

	address war_chest; // A safe vault
	
	// ICO activation period
	uint startTime;
	uint endTime;

	uint public creator_balance ;
	
	struct Seat{
		address owner;
		uint	cost;
	}
	mapping ( uint8 => Seat) table;

	function RoundTable(address war_chest) payable{
		// Ensure that the table is bootstrapped with money
		assert( msg.value >= 100 ether);
		war_chest = war_chest;

		startTime = now;
		endTime   = now + 10 days;

		table[0].owner = msg.sender;
		table[0].cost = msg.value;
	}
	function seatHolder(uint8 seat) public constant returns(address){
		return table[seat].owner;
	}
	function seatValue(uint8 seat) public constant returns(uint){
		return table[seat].cost;
	}
	function bid(address bidder, uint[] seats, uint[] bids)public payable{
		//return;
		// Validate active
		assert(now >= startTime && now < endTime);
		// Validate address
		if (bidder == 0) throw;

		// In the ICO-auction, the number of bids in one go
       	// is capped at 1, even though we use the general 
       	// multi-bid function signature 
       	//  
		// Cap the number of bids to 1
		uint NO_OF_SEATS_BID = 1;

		// Protect against short address attack
		// (doable since we have capped the arrays)
        uint expected_size = 4          // 4 byte (msg identifier)
        	+ 32                  	      // address 32 byte
        	+ 32*( 2 + NO_OF_SEATS_BID) // int[]
        	+ 32*( 2 + NO_OF_SEATS_BID); // int[]

 		assert( msg.data.length == expected_size);
 
 		// Validate data
 		assert( seats.length > 0);
 		assert( seats.length == bids.length);

 		for(uint i = 0 ; i < NO_OF_SEATS_BID; i++){
 			// Only 1-14 for sale
 			assert( 0 < seats[i]  && seats[i] < 15);
 			var seatNumber = uint8(seats[i]);

 			var valueBid = bids[i];

 			var existingSeat = table[seatNumber];
 			// Min increase 1 ether
 			if (existingSeat.cost + 1 ether <= valueBid){
 				//Bidder takes the seat
 				existingSeat.owner = bidder; 
 				existingSeat.cost = valueBid;
 			}
 			// else, money lost - medieval rules here
 		}
 		//Register how much the creator should have
 		creator_balance += 100 * bids.length;
 		// All money is stored in this contract until payout time
	}

	/**
	Creator claim function
	Can claim money at any time
	**/
	function claimHonorarium(uint val) public {
		assert(msg.sender == table[0].owner);

		assert( val <= creator_balance);
		// Decrease creator_balance before external call
		creator_balance -= val;

		msg.sender.transfer( val );
	}
	/**
	Move all funds to war-chest
	Anyone can call this
	**/
	function finalizeAuction()public {
		assert( now > endTime);
		// Creator must have already fetched their share at this point,
		// otherwise it's lost forever. 
		war_chest.transfer(this.balance);
	}

}

