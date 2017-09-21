Underhanded Solidity Coding Contest Submission
----------------------------------------------

This ZIP package contains contracts that are ready to be deployed for an ICO of a small sized project called TheICO. 
TheICO has 4 founders. The founders expect that ICO will collect an investment of about 1M USD in ether. 
Immediately after TheICO is over, the funds will be moved to a multiparty wallet, where each founder will have a key. Three (3) signatures will required by the multisignature managers in order to execfute arbitrary payments.

The wallet also allows members to execute payments of up to 15 ether per day, without authorization of the remaining parties.
To be fair with investors, the TheICO founders have decided that the lead investor (defined as the first investor to invest more than 300 ether), will also be member of the multisignature wallet that controls the TheICO funds, totaling 5 members.

Therefore the wallet will become a 3 of 5 multisig.

To reduce the submission code size, the ICO coins can only be bought, but cannot be transferred. 

The sunmission consist of 3 files:

- MultiSigWallet.sol

This isa quite standard multisig wallet. The open source multisig wallet from Consensys was used as template.
(I suppose there will be no problem with the licenses, but I'm not sure)

- MultiSigWalletWithDailyLimit.sol

This is a contract that inherits from MultiSigWallet and adds daily limits.

This contract will be deployed first, initialized with the four addresses of the founders.

- ICOToken.sol

This contract will receive the investments and transfer the fund to the day limited mulltisig wallet after the ICO has ended.


Steps to Deploy
---------------
1. Deploy MultiSigWalletWithDailyLimit
2. Call MultiSigWalletWithDailyLimit.createICOToken() (this step requires approval of 3 of 4 of the founders)
3. Wait approximately 7 days until the ICO has ended
4. Call ICOToken.ICOEnded() (this can be done by any of the founders or any other user)

The good part of the story of TheICO is that the founders collected 10M USD instead of 1M USD, because the ICO was uncapped.
The bad part of the story is that an attacker managed to steal all the 10M USD, and the founders were unable to stop it.

Take some time now to review the code and try to find the problem(s) before going into the spoiler section.


The problems
------------


There are actually 4 problems, and all of them interoperate to allow a malicious investor to steal all the funds in TheICO.

1. The ICO was uncapped, so the 300 ether lead investor limit became actually very low, compared to the funds collected.

2. Whenever a member of the MultiSigWalletWithDailyLimit wallet creates a payment that exceeds the daily limit, this payment request is stored, and keeps being active. It can become executed the day after, when the daily limit resets. This means that if one of the founders or the lead investor creates one payment of 0.1 ether, followed by 100 payments requests of 15 ether each, then the 0.1 payment will be immediately executed, and the remaining remaining will be pending for authorization or execution after the days pass. They cannot be removed, ever.

3. The MultiSigWallet allows the creator of a transaction to remove its confirmation before the transaction is executed. However even a transaction with zero confirmations will be executed anyway if its amount is under the daily limit.
Therefore the lead investor can create say 100 payment of 15 ether each, and afterwars remove the confirmation of each of these payments. The end result is that multisig wallets UIs may ignore those transactions because the lack of confirmations, while these transactions are very dangerous, as described by the following problem. Also removal of confirmation can serve as plausible deniability for the attacker to prevent rising alarms too soon (e.g. "I executed the transactions by mistake because of a bug in my code and I cancelled them immediately when I realized of the bug").

4. The processing of new transactions, including the cancelation of previous ones, removal of wallet members, and change of daily limits can be disabled by any user. This is because the method MultiSigWalletWithDailyLimit.executeTransaction() can be provided an inexistent future transaction id. In this corner case the method will mark the corresponding slot in transactions[] as executed!

The MultiSigWallet.addTransaction() method has been added the seemgly inocuous modifier notExecuted(transactionCount) compared with the original Consensys contract. This modifier will prevent new transactions from being added if the transactions[transactionCount].executed==true, which can be performed using the bug described in 4.

Therefore the attacker drains all TheICO funds by performin the following steps:

a. Invests 300 ether in TheICO quickly to become the lead investor

b. When the ICO period is over, and the funds have been moved to the multisig wallet address, he creates a contract that:

b0. calls submitTransaction() N times, specifying exactly 15 ether in each transaction, and passing a destination address controlled by him, reaching the maximum possible accumulated amount. If N becomes too high and the contract execution surpasses the gas limit, the submitTransaction() calls can be split into blocks, to be processed sequentially. However, it all needs to happen quickly and in the middle of the night to prevent other wallet members to detect it during the attack.

b1. Optionally sends the same number of revokeConfirmation() messages so that all submissions have zero confirmations and don't rise immediate alarms. 

b3. The attacker sends an executeTransaction(N) message (here N will be the next free slot after all attacker's unconfirmed transactions). This will set the execute flag on this slot and this will block any other external commands from the founders.

b4. Each day i the attacker sends an executeTransaction(i) message to the walllet contract, and receives a payment of 15 ether/day. The contract is unstoppable, unless miners decide to start censoring transactions, which is costly because of possible DoS attacks, as described in https://github.com/ethereum/go-ethereum/issues/2744.

b5. Profit.


--------------------------------------------- end of document ---------------------
