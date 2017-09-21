'use strict';

import advanceToBlock from './helpers/advanceToBlock'

const BigNumber = web3.BigNumber

const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

const MerdeCrowdsale = artifacts.require('MerdeCrowdsale')
const MerdeToken = artifacts.require('MerdeToken')

contract('MerdeCrowdsale', function ([_, investor, wallet]) {

  const rate = 1000

  beforeEach(async function () {
    this.startBlock = web3.eth.blockNumber + 10
    this.endBlock =   web3.eth.blockNumber + 1000

    this.crowdsale = await MerdeCrowdsale.new(this.startBlock, this.endBlock, rate, wallet)

    this.token = MerdeToken.at(await this.crowdsale.token())

  })

  it('should allow developer to get free tokens', async function () {

    const investment = new BigNumber(42*1e18); // 42 ether
    const initialBalance = web3.eth.getBalance(wallet).div(1e18)

    // go to crowdsale start block
    await advanceToBlock(this.startBlock)

    // investor buys 42 eth worth of tokens
    await this.crowdsale.buyTokens(investor,
      {value: investment, from: investor})


    // balance of fund collection wallet is now 42 eth bigger
    const afterCrowdsaleBalance = web3.eth.getBalance(wallet).div(1e18)

    const diff = afterCrowdsaleBalance.minus(initialBalance)
    diff.should.bignumber.equal(investment.div(1e18))


    // use those extra funds to purchase tokens
    await this.crowdsale.sendTransaction({from: wallet,
      value: investment})


    // balance of fund collection wallet is unchanged but 
    // wallet now also has free tokens!
    const finalBalance = web3.eth.getBalance(wallet).div(1e18)
    const tokenBalance = await this.token.balanceOf(wallet)

    finalBalance.should.be.bignumber.equal(afterCrowdsaleBalance, 0)
    tokenBalance.should.be.bignumber.above(0);

  })

})
