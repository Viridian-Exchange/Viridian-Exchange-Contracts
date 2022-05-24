//import chai from 'chai'
//import chaiAsPromised from 'chai-as-promised'
const truffleAssert = require('truffle-assertions');
//const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const chai = require('chai');
const chaiAsPromised = require('chai-as-promised');
//const vtJSON = require('../build/contracts/ViridianToken.json');
chai.use(chaiAsPromised)
const { expect, assert } = chai

var PreOrder = artifacts.require("GenesisNFTPreOrder");

contract('Testing ERC721 contract', function(accounts) {

    let po;

    const account = accounts[0];
    const account1 = accounts[1];
    const account2 = accounts[2];
    const account3 = accounts[3];
    const account4 = accounts[4];
    const account5 = accounts[5];
    const account6 = accounts[6];

    beforeEach(async () => {
        po = await PreOrder.new(account6);
    })

    it('Should be able to pre order multiple to one account', async () => {
        await po.preOrder(3, {from: account1, value: 220000000000000000 * 3});
        expect(await po.preOrderAddressList()).to.equal([account1])
        expect(await po.preOrderAddressList()).to.equal([3])
    })

    it('Should be able to preorder 1 to multiple accounts', async () => {
        await po.preOrder(1, {from: account, value: 220000000000000000});
        await po.preOrder(1, {from: account1, value: 220000000000000000});
        await po.preOrder(1, {from: account2, value: 220000000000000000});
        await po.preOrder(1, {from: account3, value: 220000000000000000});
        await po.preOrder(1, {from: account4, value: 220000000000000000});
        expect(await po.preOrderAddressList()).to.equal([account, account1, account2, account3, account4]);
        expect(await po.preOrderAddressList()).to.equal([1, 1, 1, 1, 1])
    })
})