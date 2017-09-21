## The Scenario

MerdeToken(MDT) is an application token for Merdapp(an very interesting and useful dapp) based on a mintable version of ERC20. It does not have a fixed total supply(but it could be capped), because it can be minted as needed. The Merdapp is in its beginning stages so the developing team is organizing a crowdsale to raise funds to support them throughout the development journey.

After careful thought the team decided to proceed with a sales model of Dutch Auction, similar to the one used for the Gnosis crowdsale. In this model, the token price starts really high and continually decreases as the time passes, so buyers can enter in the price range they assume it's fair. The auction ends when either the amount raised reaches the cap or the time period ends, determining the final price, which will be valid for all buyers, including the ones that bought earlier(at a higher price).

It's a fair model that lets the market directly dictates the final price, making projects with high interest end earlier, raising the overall evaluation.

All funds collected by the sale will be redirected to a very strict and heavily audited multisig wallet, so developers cannot withdraw it at once and enjoy a good life.


## The Exploit

All the fairness weakens as the MerdeToken team discovers an exploit that lets them manipulate the market. The idea is to send undetected money to the dutch auction contract during the crowdsale, making it end earlier than it should and therefore artificially raising the token trading price.  Since it's undetected it won't log events nor will be claimable, keeping the token supply fixed but raising the total amount collected. If the development team mint for themselves extra tokens "free of cost", like many projects do, they can fairly easily get the amount they invested to exploit back, and still make a profit.

### How it works

In solidity, anyone can forcibly send Ether to any contract, without triggering code execution, not even the fallback function. This happens when someone calls `selfdestruct` in a contract that holds ether, passing the target contract as a parameter. After mining, the target contract will have its balance raised no matter what.

### Pitfalls

It's definitely not the best exploit to get rich quickly, but it can be very profitable if used in the right conditions.

The most obvious drawback is that the attacker must spend ether proportionally to the desired attack impact, as the greater the quantity the heavier is the manipulation. So, to have a impactful attack, the exploiter must have a good amount of readily available ether. Also, this attack also implies that the team will receive less money than the intended cap, but this can be easily adjusted beforehand, making the cap equal to the intended cap plus the manipulation amount.

Another meaningful pitfall is that this attack relies on the market irrationality and herd behaviour. If, after the manipulation, the participants don't buy the token it'll probably deflate back to it's intended, non manipulated value. In light of the recent ICO's though, this does not seem to be a real concern for the crypto space.

### Advantages

This exploit provides an attractive advantage: it can only benefit the project owners and no one else. So there isn't a way to backfire and the team end up being exploited. Another strong point that it's fairly easy to go unoticed by just looking at the code. And although the transactions can be traced after, there's no easy way to distinguish an honest transaction from an exploited one.


## How to make it better

### Make a closed presale to raise attack ether
This could be a good way to not only collect ether to manipulate the market but also to mint cheap tokens that can be traded later, for the manipulated price. This can lead to significantly monetary gains and go fairly undetected, since all collected money will end up in the multsig wallet. The catch is to 'mistakenly' pass the dutch auction address as the `wallet` parameter in the `presale` contract.

### Stimulate FOMO
Before the sale starts, the team can encourage potential participants to keep an eye on the amount raised, using tools like Etherscan, so they don't entry too late and end up missing the sale. Therefore, putting undetected money not only manipulate the end result, but also pressures legit buyers to enter before they would normally, raising the prices even more.


##License

Creative Commons Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0)
