let token

const ViridianExchange = artifacts.require('ViridianExchange')

contract('ViridianToken', (accounts) => {
  const tokenName = 'Viridian Token'
  const tokenSymbol = 'VEXT'
  const tokenDecimals = 0

  beforeEach(async () => {
    token = await ViridianToken.new()
  })

  it('creation: should create an initial balance of 15000000 for the creator', async () => {
  })

  it('creation: test correct setting of vanity information', async () => {
  })

  it('creation: should succeed in creating over 100000000 - 1 (max) tokens', async () => {
  })

  // TRANSERS
  // normal transfers without approvals
  it('items: listing should be created from existing nft', async () => {
  })

  it('items: existing listing should be able to be pulled from sale', async () => {
    })

  it('transaction: nft should be able to be purchased with ETH', async () => {
  })

  it('transaction: nft should be able to be purchased with VEXT', async () => {
    })

  it('items: offer should be able to be created for existing NFT', async () => {
  })

  it('transfers: should handle zero-transfers normally', async () => {
  })
})