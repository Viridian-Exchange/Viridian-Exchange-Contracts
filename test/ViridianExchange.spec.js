let token

const ViridianExchange = artifacts.require('ViridianExchange')

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
    exchange = await ViridianExchange(token.address, nft.address);
  })

  // TRANSERS
  // normal transfers without approvals
  it('items: listing should be created from existing nft', async () => {
    exchange.makeListing.call();
    
    let listings = exchange.getListings.call();
    expect(await token.symbol()).to.equal(symbol)
    console.log(listings);
  })


  it('items: existing listing should be able to be pulled from sale', async () => {
  })


  it('transaction: nft should be able to be purchased with ETH', async () => {
  })


  it('transaction: nft should be able to be purchased with VEXT', async () => {
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