const { expect } = require("chai");

let token

const ViridianExchange = artifacts.require('ViridianExchange');
const ViridianToken = artifacts.require('ViridianToken');
const ViridianNFT = artifacts.require('ViridianNFT');

contract('ViridianExchange', (accounts) => {
    let nft;
    let token;
    let exchange;
    const name = "Viridian NFT";
    const symbol = "VNFT";

    const account1 = accounts[1];
    const tokenId1 = 1111;
    const tokenUri1 = "This is data for the token 1"; // Does not have to be unique

    const account2 = accounts[2];
    const tokenId2 = 2222;
    const tokenUri2 = "This is data for the token 2"; // Does not have to be unique

    const account3 = accounts[3];
    const tokenName = 'Viridian Token'
    const tokenSymbol = 'VEXT'
    const tokenDecimals = 0

  beforeEach(async () => {
    token = await ViridianToken.new();
    nft = await ViridianNFT.new();
    exchange = await ViridianExchange.new(token.address, nft.address);

    // Create nft with id 1
    await nft.mint(accounts[0], "https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json");
  })
  
  // TRANSERS
  // normal transfers without approvals
  it('items: listing should be created from existing nft', async () => {
    await exchange.putUpForSale("1", "1", "1", false, "0", true);
    
    let listings = await exchange.getListings.call();
    //console.log(await exchange.getListingsFromUser(accounts[0]));
    let userListings = await exchange.getListingsFromUser.call(accounts[0]);
    //console.log("UL: " + JSON.stringify(userListings));
    console.log("UL: " + listings[0]);
    expect(await listings.length).to.equal(1);
    expect(listings[0].toString()).to.equal('1');
    expect(await userListings.length).to.equal(1);
    //console.log(listings);
  })


  it('items: existing listing should be able to be pulled from sale', async () => {
    await exchange.putUpForSale("1", "1", "1", false, "0", true);
    let listings = await exchange.getListings.call();
    let userListings = await exchange.getListingsFromUser.call(accounts[0]);
    expect(await listings.length).to.equal(1);
    expect(listings[0].toString()).to.equal('1');
    expect(await userListings.length).to.equal(1);
    console.log("ULEB: " + JSON.stringify(listings));

    await exchange.pullFromSale("1");
    listings = await exchange.getListings.call();
    userListings = await exchange.getListingsFromUser.call(accounts[0]);
    console.log("ULE: " + JSON.stringify(listings));
    expect(await listings.length).to.equal(0);
    expect(await userListings.length).to.equal(0);
  })


  it('transaction: nft should be able to be purchased with ETH', async () => {
  })


  it('transaction: nft should be able to be purchased with VEXT', async () => {
    await nft.safeTransferFrom(accounts[0], accounts[1], "1");
    await exchange.putUpForSale("1", "100", "1", false, "0", true, {from: accounts[1]});
    let listings = await exchange.getListings.call({from: accounts[1]});
    let userListings = await exchange.getListingsFromUser(accounts[1]);
    expect(await listings.length).to.equal(1);
    expect(listings[0].toString()).to.equal('1');
    expect(await userListings.length).to.equal(1);

    const balanceBefore = await token.balanceOf.call(accounts[ 0 ])

    console.log("VEXT Balance: " + balanceBefore);

    let ownedNFTs = await nft.getOwnedNFTs()
    console.log("ONFTS: " + JSON.stringify(ownedNFTs));
    expect(await ownedNFTs.length).to.equal(0);

    console.log(userListings[0].price);

    // await exchange.buyNFTWithVEXT("1");

    // const balanceAfter = await token.balanceOf.call(accounts[ 0 ])

    // assert.strictEqual(balanceAfter, balanceBefore - 100);
    // expect(await ownedNFTs.length).to.equal(1);

  })


  it('items: offer should be able to be created for existing NFT', async () => {
  })


  it('transaction: should be able to accept ETH offer', async () => {
  })


  it('transaction: should be able to accept VEXT offer', async () => {
  })


  it('transaction: should be able to accept just NFT offer', async () => {
  })  


  it('transaction: should be able to accept ETH/NFT hybrid offer', async () => {
  })  


  it('transaction: should be able to accept VEXT/NFT hybrid offer', async () => {
  })


  it('transfers: should handle zero-transfers normally', async () => {
  })
})