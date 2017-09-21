This submission implements a MerdetokenSale contract that allows certain participants to get more tokens than they ought to.

MerdetokenSale design
- Fixed start and end blocks, accepting contributions while open
- After it closes, if more than the minimum was raised, can finalize the sale. Token price is calculated at this time which is based on the total amount raised and the fixed token supply
- Buyers submit their claim transactions which issues with respective tokens amount as per their contribution
- For simplicity, the sale contract does not implemented any forwarding of funds onto a wallet contract nor any secure withdrawal functions
- Included is a standard ERC20 Token contract which contains no (intentional) vulnerabilities

Exploit
Due to the DIV opcode always truncating the result (http://solidity.readthedocs.io/en/develop/types.html?#integers) the tokenPrice calculation will be rounded down, i.e. if tokenPrice in decimal was 12.73, it will be assigned as 12. 

Lower value for the token price when claiming tokens means a higher number of tokens issued per contribution. This leads to the token pool been depleted before everyone can claim their rightful tokens.

To ensure we don't get caught out with tokenPrice decimal <1 meaning the tokenPrice becomes 0 and no one gets any tokens, we have to initialize the sale with minToRaise >= tokenSupply

Sample sale development:
MerdetokenSale contract is deployed with the following parameters
const duration = 100;
const minToRaise = 5 * 10 ** 18 + 1;
const tokenSupply = 5 * 10 ** 18;

There are a number of contributions, bringing the totalSupply to 9950000000000000000
Sale is finalized and tokenPrice = 9.95 * 10 ** 18 / 5 * 10 ** 18 = 1 (true 1.99)

The first claims to go through will get almost twice (1.99 times exactly) what they deserve. It's a good thing we can hide behind these other users that unknowlingly joined us in earning more tokens than they paid for.