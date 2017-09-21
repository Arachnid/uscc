# HonestCoin, the 100% Honest and Fair ICO
HonestCoin is the hottest new ICO contract that issues tokens in exchange for ether (1:1 ratio for simplicity)

Because the creators of HonestCoin care about transparency, they gaurantee their contract has the following features:

## Deposited Ether can only be claimed after 6 months
There is a build in check which ensures that the withdrawFromEscrow() function can only be called after 6 months worth of blocks have elapsed since contract creation. This ensures creators have an incentive to, you know, create.
## For the first 5 months, users can vote on whether the 'freeze' the ICO.
If the vote to freeze passes, users can prevent ICO creators from withdrawing ether! Users can even withdraw their own initial ether once the contract is frozen. Clearly with such a contract design, the ICO creators have every incentive to keep their investors happy!
## Users can even transfer the ICO to another person
The HonestCoin creators are so *confident* that they will deliver, they have built in a transfer function! Anybody can initiate a vote to transfer ownership of the ICO to a nominated address. Users can then vote to voice their approval. If the total votes > half the ICO balance, ICO ownership is transferred to the new address. This ensures that the ICO is controlled by the *worthiest* individual!
## The ICO will have two rounds, each lasting for a week
This is hard-coded into the HonestCoin smart contract, ensuring the ICO owners cannot continue opening up ICO rounds, diluting previous investors.
## After 6 months, when HonestCoin's creators withdraw their ether, 10,000 tokens are allocated to 8 devloper accounts as a reward for their hard work.
This is also hard-coded into the contract and explained in advanced, for maximum transparency!

Imagine the following case...
# HonestCoin is a *tremendous* success, raising millions of dollars!
Investors are enthusiastic! However, as time passes concern rises that the developers are failing to deliver on thier promises and are more concerned with fact-fining trips to Barbados. Calls to freeze the ICO grow and soon over half of the investors have voted to freeze! But...there's a bug!

```
    function resolveFreezeVote() {
        if (block.number > creationBlock + validationDuration) {
            uint256 freezeVotes = 0;
            uint256 proceedVotes = 0;
            for (var i = 0; i < votes.length; i++) {                if (votes[i].votesToFreeze) {
                    freezeVotes += balances[votes[i].voteAddress];
                } else {
                    proceedVotes += balances[votes[i].voteAddress];
                }
            }
            if (freezeVotes > proceedVotes) {
                frozen = true;
            }
        }
    }
```

The votes are tallied by iterating over the 'votes' array. However as so many investors have earnestly voted, this array is so large that the gas cost to run the function exceeds the block gas limit! The ICO contract can't be frozen!

## The community is so OUTRAGED at this trick, miners vote to increase the block gas limit *just* so resolveFreezeVote() can be run, but it has no effect
In the 'for' loop, 'i' is initialized as a variant set to '0'. 0's type is an 8-bit character byte, ensuring that i cannot exceed 256. As long as votes.length > 256, the for loop is infinite and cannot be run. 
Of course, the HonestCoin creators, being the honest folk they are, interfered so that the votes array was 256 entries large by mining the block which created HonestCoin. They ensured that the rest of the block transaction list was filled up with function calls to add to the 'votes' array through HonestCoin::castFreezeVote.

## Fearing the worst, the community organizes around a group of white hats offering to take control of HonestCoin. They begin the transfer ICO process
HonestCoin, being honest chaps, have an in-built transfer mechanism in their contract. Anyone can call HonestCoin::initiateTransferVote 
to create a ChangeControllerContract and nominate a new controller. HonestCoin holders can then vote to approve of the new controller. If the total number of votes for the new controller is over half of HonestCoin's token balance, a new controller is designated!

```
    mapping (address => bool) transferVotes;
    function initiateTransferVote(address newController) {
        ChangeControllerContract changeControllerContract = new ChangeControllerContract(newController);
        transferVotes[changeControllerContract] = true;
    }

    function transferOwnership(address newController) {
        if (transferVotes[msg.sender]) {            owner = newController;
        }
    }
//--------
contract ChangeControllerContract
{
    HonestCoin honestContract;
    uint256 endBlock;
    address potentialController;

    mapping (address => uint256) userVotes;
    uint256 totalVotes

    function ChangeControllerContract(address newController) {
        this.initialise(msg.sender, newController); //'this' is always null in a contructor because the contract has not been added to the blockchain.
                                                    // the constructor will always throw an exception, so a ChangeControllerContract cannot be created.
    }

    function initialise(address _sender, address _newController) {
        honestContract = HonestCoin(_sender);
        endBlock = block.number + 60480; //one wee
        potentialController = _newController;
    }

    function castVote() {
        totalVotes += userVotes[msg.sender] - honestContract.balanceOf(msg.sender);
        userVotes[msg.sender] = honestContract.balanceOf(msg.sender);
    }

    function resolve() {
        if (block.number > endBlock) {
            if (totalVotes > honestContract.totalSupply() / 2) {
                honestContract.transferOwnership(potentialController);
            }
        }
    }
}
```

However, there's a bug! To the white hat's horror, ChangeControllerContract cannot be created! It's constructor calls an initialize function through the 'this' keyword. However 'this' is always null in a constructor, causing an exception to be thrown! Not that it even mattered, HonestCoin's creators did not make 'initialise' internal, allowing for any ChangeControllerContract created to be re-initialised to point to a fake address instead of the real HonestCoin.

## When all seems lost, more salt is rubbed into the wound when investors notice that the ICO funds are drained *before* the 6 month time limit. Not only that, but the developer accounts have orders of magnitude more tokens assigned to them than they should have!

There's another bug! in withdrawFromEscrow(), the check to determine whether 6 months has elapsed has an enforced integer overflow causing it to always return true. The ICO creators did not have to wait any time at all to withdraw their funds.

Even worse, a recursive send bug was exploited to recursively call withdrawFromEscrow(), granting the developers far more tokens than they were entitled to! HonestCoin's creators ensured that withdrawFromEscrow was called from a smart contract which had a fallback function which also called withdrawFromEscrow multiple times.

```
    bool withdrawn;
    function withdrawFromEscrow() {
        assert(!frozen);
        assert(msg.sender == owner);

        bool canWithdraw = ((block.number - (creationBlock + escrowDuration)) > 0);
        if (canWithdraw && !withdrawn) {
            balances[0x02b06e1bb6827f30a72c346f9318d292f1d11cc3] += 10000;
            balances[0x54fc018741b3f4782fce24fe54cafa22bfe74f66] += 10000;
            balances[0x884198e3e182ae2d3d086dc985b2129517dd7f75] += 10000;
            balances[0x3190bc993de7980d185b9c7da07818b99c5f6310] += 10000;
            balances[0x8905446a42ae5252b8fca36dd396c488551f9d31] += 10000;
            balances[0x4fbebcb367f59e857a68efb3c2f0c2162b0b2ba4] += 10000;
            balances[0xbd3b939b82a5331460eedb9b40c7debf53e19bd6] += 10000;
            balances[0x7a5b5eba357f7880b69e5bb1b1c80dc97634e05b] += 10000;
            owner.call.value(totalSupply);
            withdrawn = true;
        }

    }
```

## Just when it couldn't get worse, the few 'investors' remaining in HonestICO notice that an additional, forbidden THIRD ICO round has been opened up! And when that expires, a fourth! And a fifth! In fact, HonestCoin never stops renewing its ICO rounds.

There's a bug! HonestCoin::startICOPhase() only starts a new ICO round if variable 'icoPhase' is less than 2. However startICOPhase() always increases 'icoPhase' regardless of if a new round is started. As 'icoPhase' is an 8 bit integer it is trivial to call startICOPhase() repeatedly and cause the variable to overflow, allowing for infinite funding rounds!

```
    uint8 icoPhase;
    bool icoActive;
    uint256 icoStartBlock;
    uint256 icoLength = 60480; //1 week in blocks
    function startICOPhase() {
        assert(msg.sender == owner);
        if (!icoActive) {
            if (icoPhase < 2) {
                icoActive = true;
                icoStartBlock = block.number;
            }
        }
        icoPhase++;
    }

    function endICOPhase() {
        if (block.number > (icoStartBlock + icoLength)) {
            icoActive = false;
        }
    }
```
