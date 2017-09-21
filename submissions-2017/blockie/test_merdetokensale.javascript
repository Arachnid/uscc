assert = require('assert')
fs = require('fs')
merdeweb = require('web3')
compiler = require('solc')
web = new merdeweb(new merdeweb.providers.HttpProvider("http://localhost:8545"));

contract_code = fs.readFileSync('merdetokensale.sol').toString();
contract_program = compiler.compile(contract_code);
test_contract = web.eth.contract(JSON.parse(contract_program.contracts[':MerdetokenSale'].interface));
token_contract = web.eth.contract(JSON.parse(contract_program.contracts[':Merdetoken'].interface));
contract_bytecode = contract_program.contracts[':MerdetokenSale'].bytecode;

var sale_owner = web.eth.accounts[0];
var participant_1 = web.eth.accounts[1];
var participant_2 = web.eth.accounts[2];
var sale_wallet_address = web.eth.accounts[6];

console.log("Participants:\n\tSale owner: " + sale_owner + "\n\tSale wallet: " + sale_wallet_address + "\n\tParticipant #1: " + participant_1 + "\n\tParticipant #2: " + participant_2);

// Sale owner deploys sale contract pointing sale wallet address
instance = test_contract.new(sale_wallet_address, 1, 3, {
    from: sale_owner,
         data: contract_bytecode,
         gas: 999999999 },
         function (error, contract) {
             if(!error) {
                 if(!contract.address) {
                     console.log("Deploying Merdetoken Sale ...\n" + contract.transactionHash);
                 } else {
                     console.log("Testing ...\n");
                     var sale = test_contract.at(contract.address);
                     print_sale_balance(contract.address, sale_wallet_address);


                     print_wallet_balance("Participant-1 wallet", participant_1);
                     participant_buy_ticket(sale, "Participant #1", participant_1, 1);
                     print_sale_balance(contract.address, sale_wallet_address);
                     participant_buy_ticket(sale, "Participant #1", participant_1, 6);
                     print_sale_balance(contract.address, sale_wallet_address);

                     console.log("=> Owner tries to setThreshold to 10\n");
                     var result = contract.setThreshold(10, { from: sale_owner, gas: 999999999 });
                     console.log(" * Owner sets threshold to 10 [OK]\n" + result);

                     console.log("=> Participant #1 tries to draw win condition\n");
                     var result = contract.drawWinner({ from: participant_1, gas: 999999999 });
                     console.log(" * Participant #1 draws condition [OK]\n" + result);

                     console.log("=> Participant #1 tries to refund Ether\n");
                     print_wallet_balance("Participant-1 wallet", participant_1);
                     var result = contract.claimEth({ from: participant_1, gas: 999999999 });
                     console.log(" * Participant #1 claims Ether [OK]\n" + result);
                     print_wallet_balance("Participant-1 wallet", participant_1);

                     // To test this here,
                     // line merdertokensale.sol:319 must be commented out:
                     //     require(blockTimeNow > (endTimeBlock + 30 days));
                     console.log("=> Owner tries to transferFunds to 10\n");
                     print_sale_balance(contract.address, sale_wallet_address);
                     var result = sale.transferFunds({ from: sale_owner, gas: 999999999 });
                     console.log(" * Owner transferFunds ether [OK]\n" + result);
                     print_sale_balance(contract.address, sale_wallet_address);

                     console.log("=> Participant #1 tries to read his token balance from: " + sale.token() + "\n");
                     var token = token_contract.at(sale.token());
                     var result = token.balanceOf(participant_1, { from: participant_1, gas: 999999999 });
                     console.log(" * Participant #1 reads his own token balance [OK]\n" + result);
                 }
             }
         }
);

function print_wallet_balance(name, address) {
    console.log(name + " balance: " + web.eth.getBalance(address));
}

function print_sale_balance(contractAddress, saleWalletAddress) {
    print_wallet_balance("\n============================================\nSale Contract", contractAddress);
    print_wallet_balance("Sale wallet", saleWalletAddress);
    console.log("============================================\n");
}

function participant_buy_ticket(contract, name, address, valueInEth) {
    console.log("=> " + name + " tries to buy " + valueInEth + " more for himself\n");
    var value_in_wei = web.toWei(valueInEth, "ether");
    var result = contract.buy(address, { from: address, value: value_in_wei, gas: 999999999 });
    console.log(" * " + name + " : buys " + valueInEth + " for himself [OK]\n" + result);
    print_wallet_balance(name + " wallet", address);
}
