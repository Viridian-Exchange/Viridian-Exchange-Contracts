// const Web3 = require("web3");

// const web3 = new Web3(Web3.givenProvider || "HTTP://127.0.0.1:7545");

// const { expect } = require("chai");

// let token

// const truffleAssert = require('truffle-assertions');

// const ViridianExchange = artifacts.require('ViridianExchange');
// const ViridianExchangeOffers = artifacts.require('ViridianExchangeOffers');
// const ViridianToken = artifacts.require('ViridianToken');
// const ViridianNFT = artifacts.require('ViridianNFT');
// const ViridianPack = artifacts.require('ViridianPack');

// contract('ViridianExchange', (accounts) => {
//     let nft;
//     let token;
//     let exchange;
//     const name = "Viridian NFT";
//     const symbol = "VNFT";

//     const account1 = accounts[1];
//     const tokenId1 = 1111;
//     const tokenUri1 = "This is data for the token 1"; // Does not have to be unique

//     const account2 = accounts[2];
//     const tokenId2 = 2222;
//     const tokenUri2 = "This is data for the token 2"; // Does not have to be unique

//     const account3 = accounts[3];
//     const tokenName = 'Tether Token'
//     const tokenSymbol = 'USDT'
//     const tokenDecimals = 0

//   beforeEach(async () => {
//     token = await ViridianToken.new();
//     nft = await ViridianNFT.new();
//     pack = await ViridianPack.new(nft.address);
//     exchange = await ViridianExchange.new(token.address, nft.address, pack.address);
//     exof = await ViridianExchangeOffers.new(token.address, nft.address, pack.address);

//     // Create nft with id 1
//     await nft.mint(accounts[0], "https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json");
//     //await nft.setExchangeAddress(exchange.address);
//     await nft.setApprovalForAll(exchange.address, true, {from: accounts[0]});
//     await nft.setApprovalForAll(exchange.address, true, {from: accounts[1]});
//     await nft.setApprovalForAll(exchange.address, true, {from: accounts[2]});

//     await nft.setApprovalForAll(exof.address, true, {from: accounts[0]});
//     await nft.setApprovalForAll(exof.address, true, {from: accounts[1]});
//     await nft.setApprovalForAll(exof.address, true, {from: accounts[2]});
//     token.approve(accounts[0], 0);
//     token.approve(accounts[1], 0);
//     token.approve(accounts[2], 0);
//     //token.approve(accounts[1], '500');
//     //await web3.sendTransaction({to:exchange, from:accounts[3], value:web3.toWei("90", "ether")});
//     //console.log("APVL: " + JSON.stringify(await nft.isApprovedForAll(accounts[0], exchange.address)));
//   })
  
//   // TRANSERS
//   // normal transfers without approvals
//   it('items: listing should be created from existing nft', async () => {
//     //nft.approve(exchange.address, '1');
//     //nft.safeTransferFrom(accounts[0], exchange.address, '1');
//     await exchange.putUpForSale("1", "1", "1", "0", token.address, true);
    
//     let listings = await exchange.getListings.call();
//     //console.log(await exchange.getListingsFromUser(accounts[0]));
//     let userListings = await exchange.getListingsFromUser.call(accounts[0]);
//     //console.log("UL: " + JSON.stringify(userListings));
//     console.log("UL: " + listings[0]);
//     expect(await listings.length).to.equal(1);
//     expect(listings[0].toString()).to.equal('1');
//     expect(await userListings.length).to.equal(1);
//     //console.log(listings);
//   })


//   it('items: existing listing should be able to be pulled from sale', async () => {
//     await exchange.putUpForSale("1", "1", "1", "0", token.address, true);
//     let listings = await exchange.getListings.call();
//     let userListings = await exchange.getListingsFromUser.call(accounts[0]);
//     expect(await listings.length).to.equal(1);
//     expect(listings[0].toString()).to.equal('1');
//     expect(await userListings.length).to.equal(1);
//     console.log("ULEB: " + JSON.stringify(listings));
//     await token.approve(exchange.address, 0);
//     await exchange.pullFromSale("1");
//     listings = await exchange.getListings.call();
//     userListings = await exchange.getListingsFromUser.call(accounts[0]);
//     console.log("ULE: " + JSON.stringify(listings));
//     expect(await listings.length).to.equal(0);
//     expect(await userListings.length).to.equal(0);
//     let allowanceAfter = await token.allowance(accounts[0], exchange.address);
//     console.log("ALLOWANCE: " + JSON.stringify(allowanceAfter));
//     //expect(allowanceAfter.toString()).to.equal('0');
//   })

//   it('items: allowance should not return to 0 with two listings', async () => {
//     await nft.mint(accounts[0], "https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd2.json");
//     await exchange.putUpForSale("1", "100", "1", "0", token.address, true);
//     await token.approve(exchange.address, 0);
//     await token.approve(exchange.address, 100);

//     await exchange.putUpForSale("2", "200", "1", "0", token.address, true);
//     await token.approve(exchange.address, 0);
//     await token.approve(exchange.address, 100 + 200);

//     let allowanceBefore = await token.allowance(accounts[0], exchange.address);
//     //console.log("ALOWBEF: " + JSON.stringify(300));
//     //expect(allowanceBefore.toString()).to.equal('300');

//     let listings = await exchange.getListings.call();
//     let userListings = await exchange.getListingsFromUser.call(accounts[0]);
//     expect(await listings.length).to.equal(2);
//     expect(listings[0].toString()).to.equal('1');
//     expect(await userListings.length).to.equal(2);
//     console.log("ULEB: " + JSON.stringify(listings));
//     await token.approve(exchange.address, 0);
//     await token.approve(exchange.address, 200);
//     await exchange.pullFromSale("1");
//     listings = await exchange.getListings.call();
//     userListings = await exchange.getListingsFromUser.call(accounts[0]);
//     console.log("ULE: " + JSON.stringify(listings));
//     expect(await listings.length).to.equal(1);
//     expect(await userListings.length).to.equal(1);
//     let allowanceAfter = await token.allowance(accounts[0], exchange.address);
//     //expect(allowanceAfter.toString()).to.equal('200');
//   })


//   it('transaction: nft should be able to be purchased with ERC20', async () => {
//     await nft.safeTransferFrom(accounts[0], accounts[1], "1");
//     await token.approve(exchange.address, 0);
//     await token.approve(exchange.address, 100);
//     await exchange.putUpForSale("1", "100", "1", "0", token.address, true, {from: accounts[1]});
//     let listings = await exchange.getListings.call({from: accounts[1]});
//     let userListings = await exchange.getListingsFromUser(accounts[1]);
//     expect(await listings.length).to.equal(1);
//     expect(listings[0].toString()).to.equal('1');
//     expect(await userListings.length).to.equal(1);

//     const balanceBefore = await token.balanceOf.call(accounts[ 0 ])

//     console.log("ERC20 Balance bef: " + balanceBefore);

//     let ownedNFTs = await nft.getOwnedNFTs({from: accounts[0]})
//     let ownedNFTsOther = await nft.getOwnedNFTs({from: accounts[1]})
//     console.log("ONFTS__)O: " + JSON.stringify(ownedNFTs));
//     console.log("ONFTSOOO: " + JSON.stringify(ownedNFTsOther));
//     expect(await ownedNFTs.length).to.equal(0);
//     expect(await ownedNFTsOther.length).to.equal(1);

//     //console.log("Cur price: " + JSON.stringify(userListings[0].price));

//     //await token.approve(exchange.address, 100);
//     //await token.approve(exchange.address, 0);
//     await exchange.buyNFTWithERC20(1);

//     const balanceAfter = await token.balanceOf.call(accounts[ 0 ])
//     ownedNFTs = await nft.getOwnedNFTs();
//     ownedNFTsOther = await nft.getOwnedNFTs({from: accounts[1]});

//     //console.log("ERC20 Balance aft: " + balanceAfter.toString());
//     listings = await exchange.getListings.call({from: accounts[1]});
//     userListings = await exchange.getListingsFromUser(accounts[1]);

//     expect(await listings.length).to.equal(0);
//     expect(await userListings.length).to.equal(0);
//     assert.strictEqual(balanceBefore.toString(), "200000000000000000000000000");
//     assert.strictEqual(balanceAfter.toString(), "199999999999999999999999900");
//     expect(await ownedNFTs.length).to.equal(1);
//     expect(await ownedNFTsOther.length).to.equal(0);
//   })

//   it('transaction: nft should be able to be purchased with ERC20', async () => {
//     await nft.safeTransferFrom(accounts[0], accounts[1], "1");
//     await exchange.putUpForSale("1", "500", "1", "0", token.address, true, {from: accounts[1]});
//     let listings = await exchange.getListings.call({from: accounts[1]});
//     let userListings = await exchange.getListingsFromUser(accounts[1]);
//     expect(await listings.length).to.equal(1);
//     expect(listings[0].toString()).to.equal('1');
//     expect(await userListings.length).to.equal(1);

//     const balanceBefore = await token.balanceOf.call(accounts[ 0 ])

//     //console.log("ERC20 Balance bef: " + balanceBefore);

//     let ownedNFTs = await nft.getOwnedNFTs()
//     //console.log("ONFTS: " + JSON.stringify(ownedNFTs));
//     expect(await ownedNFTs.length).to.equal(0);

//     //console.log("Cur price: " + JSON.stringify(userListings[0].price));

//     await token.approve(exchange.address, 0);
//     await token.approve(exchange.address, 500);
//     await exchange.buyNFTWithERC20(1);

//     const balanceAfter = await token.balanceOf.call(accounts[ 0 ])
//     ownedNFTs = await nft.getOwnedNFTs()

//     //console.log("ERC20 Balance aft: " + balanceAfter.toString());

//     assert.strictEqual(balanceBefore.toString(), "200000000000000000000000000");
//     assert.strictEqual(balanceAfter.toString(), "199999999999999999999999500");
//     expect(await ownedNFTs.length).to.equal(1);

//   })

//   it('transaction: nft should be able to be purchased with ERC20 if approval is higher', async () => {
//     await nft.safeTransferFrom(accounts[0], accounts[1], "1");
//     await exchange.putUpForSale("1", "500", "1", "0", token.address, true, {from: accounts[1]});
//     let listings = await exchange.getListings.call({from: accounts[1]});
//     let userListings = await exchange.getListingsFromUser(accounts[1]);
//     expect(await listings.length).to.equal(1);
//     expect(listings[0].toString()).to.equal('1');
//     expect(await userListings.length).to.equal(1);

//     const balanceBefore = await token.balanceOf.call(accounts[ 0 ])

//     //console.log("ERC20 Balance bef: " + balanceBefore);

//     let ownedNFTs = await nft.getOwnedNFTs();
//     //console.log("ONFTS: " + JSON.stringify(ownedNFTs));
//     expect(await ownedNFTs.length).to.equal(0);

//     //console.log("Cur price: " + JSON.stringify(userListings[0].price));

//     await token.approve(exchange.address, 0);
//     await token.approve(exchange.address, 600);
//     await exchange.buyNFTWithERC20(1);

//     const balanceAfter = await token.balanceOf.call(accounts[ 0 ])
//     ownedNFTs = await nft.getOwnedNFTs()

//     //console.log("ERC20 Balance aft: " + balanceAfter.toString());

//     assert.strictEqual(balanceBefore.toString(), "200000000000000000000000000");
//     assert.strictEqual(balanceAfter.toString(), "199999999999999999999999500");
//     expect(await ownedNFTs.length).to.equal(1);

//   })


//   it('items: offer should be able to be created for existing NFT', async () => {
//     await nft.safeTransferFrom(accounts[0], accounts[1], "1");
//     await nft.mint(accounts[0], "https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json");
//     await nft.mint(accounts[0], "https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json");
//     await exof.makeOffer(accounts[1], ['2', '3'], [], '300', ['1'], [], '100', token.address, "1");
//     let offers = await exof.getOffers.call({from: accounts[1]});
//     let userOffers = await exof.getOffersFromUser(accounts[1]);

//     console.log("UL: " + offers[0]);
//     expect(await offers.length).to.equal(1);
//     expect(offers[0].toString()).to.equal('1');
//     expect(await offers.length).to.equal(1);
//   })

//   it('items: offer should not be able to be created for existing NFT when not owned NFTs are included', async () => {
//     await nft.safeTransferFrom(accounts[0], accounts[1], "1");
//     await nft.mint(accounts[0], "https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json");
//     await nft.mint(accounts[0], "https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json");
//     await truffleAssert.reverts(
//       exof.makeOffer(accounts[1], ['1', '3'], [], '300', ['1'], [], '100', token.address, "1"),
//       "Offered account must own all requested NFTs"
//     );
//   })

//   it('items: offer should not be able to be created for existing NFT when not owned NFTs are included', async () => {
//     await nft.safeTransferFrom(accounts[0], accounts[1], "1");
//     await nft.mint(accounts[0], "https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json");
//     await nft.mint(accounts[0], "https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json");
//     await truffleAssert.reverts(
//       exof.makeOffer(accounts[1], ['2', '3'], [], '300', ['3'], [], '100', token.address, "1"),
//       "Offering account must own all offered NFTs"
//     );
//   })

//   it('items: offer should be able to be cancelled', async () => {
//     await nft.safeTransferFrom(accounts[0], accounts[1], "1");
//     await nft.mint(accounts[0], "https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json");
//     await nft.mint(accounts[0], "https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json");
//     await exof.makeOffer(accounts[1], ['2', '3'], [], '300', ['1'], [], '100', token.address, "1")
//     let offers = await exof.getOffers.call({from: accounts[1]});
//     let userOffers = await exof.getOffersFromUser(accounts[1]);

//     console.log("UL: " + offers[0]);
//     expect(await offers.length).to.equal(1);
//     expect(offers[0].toString()).to.equal('1');
//     expect(await offers.length).to.equal(1);

//     await exof.cancelOffer("1");
//     offers = await exof.getOffers.call();
//     userOffers = await exof.getOffersFromUser.call(accounts[0]);
//     console.log("ULE: " + JSON.stringify(offers));
//     expect(await offers.length).to.equal(0);
//     expect(await userOffers.length).to.equal(1);
//   })

// //   it('transaction: should be able to accept ETH offer', async () => {
// //   })


//   it('transaction: should be able to accept ERC20 offer', async () => {
//     await nft.safeTransferFrom(accounts[0], accounts[1], "1");
//     await nft.mint(accounts[0], "https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json");
//     await nft.mint(accounts[0], "https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json");
//     await exof.makeOffer(accounts[1], [], [], '100', [], [], '200', token.address, "1")
//     let offers = await exof.getOffers.call({from: accounts[1]});
//     let userOffers = await exof.getOffersFromUser(accounts[1]);
//     console.log("UL: " + offers[0]);
//     expect(await offers.length).to.equal(1);
//     expect(offers[0].toString()).to.equal('1');
//     expect(await offers.length).to.equal(1);


//   })

//   it('transaction: should be able to accept just NFT offer', async () => {
//     await nft.safeTransferFrom(accounts[0], accounts[1], "1");
//     await nft.mint(accounts[0], "https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json");
//     await nft.mint(accounts[0], "https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json");
//     await exof.makeOffer(accounts[1], ['2', '3'], [], '0', ['1'], [], '0', token.address, "1")
//     let offers = await exof.getOffers.call({from: accounts[1]});
//     let userOffers = await exof.getOffersFromUser(accounts[1]);
//     console.log("UL: " + offers[0]);
//     expect(await offers.length).to.equal(1);
//     expect(offers[0].toString()).to.equal('1');
//     expect(await offers.length).to.equal(1);


//   })  


// //   it('transaction: should be able to accept ETH/NFT hybrid offer', async () => {
// //   })  


//   it('transaction: should be able to accept ERC20/NFT hybrid offer', async () => {
//     await token.transfer(accounts[1], '500');
//     await nft.safeTransferFrom(accounts[0], accounts[1], "1");
//     await nft.mint(accounts[0], "https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json");
//     await nft.mint(accounts[0], "https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json");
//     await token.approve(exof.address, 0, {from: accounts[1]});
//     await token.approve(exof.address, 100, {from: accounts[1]});
//     //await token.approve(exchange.address, 300);
//     await exof.makeOffer(accounts[1], ['2', '3'], [], '300', ['1'], [], '100', token.address, "1")
//     let offers = await exof.getOffers.call({from: accounts[1]});
//     let userOffers = await exof.getOffersFromUser(accounts[1]);
//     console.log("UL: " + offers[0]);
//     expect(await offers.length).to.equal(1);
//     expect(offers[0].toString()).to.equal('1');
//     expect(await offers.length).to.equal(1);

//     const balanceBefore = await token.balanceOf.call(accounts[ 0 ]);
//     const balanceBefore1 = await token.balanceOf.call(accounts[ 1 ]);

//     console.log("to: " + accounts[1]);
//     console.log("Who owns 1: " + await nft.ownerOf("1"));

//     console.log("from: " + accounts[0]);
//     console.log("Who owns 2: " + await nft.ownerOf("2"));
//     console.log("Who owns 3: " + await nft.ownerOf("3"));

//     let ownedNFTs = await nft.getOwnedNFTs();
//     let ownedNFTs1 = await nft.getOwnedNFTs({from: accounts[1]});
//     //console.log("ONFTS: " + JSON.stringify(ownedNFTs));
//     expect(await ownedNFTs.length).to.equal(2);
//     expect(await ownedNFTs1.length).to.equal(1);

//     //console.log("Cur price: " + JSON.stringify(userListings[0].price));
//     await token.approve(exof.address, 0);
//     await token.approve(exof.address, 300);
//     exof.acceptOfferWithERC20('1', {from: accounts[1]});

//     offers = await exchange.getListings.call();
//     userOffers = await exof.getOffersFromUser.call(accounts[0]);
//     console.log("ULE: " + JSON.stringify(offers));
//     expect(await offers.length).to.equal(0);
//     expect(await userOffers.length).to.equal(1);

//     const balanceAfter = await token.balanceOf.call(accounts[ 0 ])
//     const balanceAfter1 = await token.balanceOf.call(accounts[ 1 ])
//     ownedNFTs = await nft.getOwnedNFTs();
//     ownedNFTs1 = await nft.getOwnedNFTs({from: accounts[1]});

//     expect(await ownedNFTs.length).to.equal(1);
//     expect(await ownedNFTs1.length).to.equal(2);

//     //console.log("ERC20 Balance aft: " + balanceAfter.toString());

//     assert.strictEqual(balanceBefore.toString(), "199999999999999999999999500");
//     assert.strictEqual(balanceAfter.toString(),  "199999999999999999999999300");
//     assert.strictEqual(balanceBefore1.toString(), "500");
//     assert.strictEqual(balanceAfter1.toString(), "700");

//   })

//   it('transaction: should not be able to accept ERC20/NFT hybrid offer when balance is too low', async () => {
//    //await token.transfer(accounts[1], '500');
//     await nft.safeTransferFrom(accounts[0], accounts[2], "1");
//     await nft.mint(accounts[1], "https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json");
//     await nft.mint(accounts[1], "https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json");
//     await token.approve(exof.address, 0, {from: accounts[1]});
//     await token.approve(exof.address, 100, {from: accounts[1]});
//     //await token.approve(exchange.address, 300);
//     await exof.makeOffer(accounts[2], ['2', '3'], [], '300', ['1'], [], '100', token.address, "1", {from: accounts[1]})
//     let offers = await exof.getOffers.call({from: accounts[2]});
//     let userOffers = await exof.getOffersFromUser(accounts[2]);
//     console.log("UL: " + offers[0]);
//     expect(await offers.length).to.equal(1);
//     expect(offers[0].toString()).to.equal('1');
//     expect(await offers.length).to.equal(1);

//     const balanceBefore = await token.balanceOf.call(accounts[ 1 ]);
//     const balanceBefore1 = await token.balanceOf.call(accounts[ 2 ]);

//     console.log("to: " + accounts[2]);
//     console.log("Who owns 1: " + await nft.ownerOf("1"));

//     console.log("from: " + accounts[1]);
//     console.log("Who owns 2: " + await nft.ownerOf("2"));
//     console.log("Who owns 3: " + await nft.ownerOf("3"));

//     let ownedNFTs = await nft.getOwnedNFTs({from: accounts[1]});
//     let ownedNFTs1 = await nft.getOwnedNFTs({from: accounts[2]});
//     //console.log("ONFTS: " + JSON.stringify(ownedNFTs));
//     expect(await ownedNFTs.length).to.equal(2);
//     expect(await ownedNFTs1.length).to.equal(1);

//     //console.log("Cur price: " + JSON.stringify(userListings[0].price));
//     await token.approve(exof.address, 0);
//     await token.approve(exof.address, 300);

//     await truffleAssert.reverts(
//     exof.acceptOfferWithERC20('1', {from: accounts[2]}),
//     ''//'ERC20: transfer amount exceeds balance'
//     );

//     // offers = await exchange.getListings.call();
//     // userOffers = await exof.getOffersFromUser.call(accounts[0]);
//     // console.log("ULE: " + JSON.stringify(offers));
//     // expect(await offers.length).to.equal(0);
//     // expect(await userOffers.length).to.equal(1);

//     const balanceAfter = await token.balanceOf.call(accounts[ 1 ])
//     const balanceAfter1 = await token.balanceOf.call(accounts[ 2 ])
//     ownedNFTs = await nft.getOwnedNFTs({from: accounts[1]});
//     ownedNFTs1 = await nft.getOwnedNFTs({from: accounts[2]});

//     expect(await ownedNFTs.length).to.equal(2);
//     expect(await ownedNFTs1.length).to.equal(1);

//     console.log("ERC20 Balance aft: " + balanceAfter.toString());

//     assert.strictEqual(balanceBefore.toString(), "0");
//     assert.strictEqual(balanceAfter.toString(),  "0");
//     assert.strictEqual(balanceBefore1.toString(), "0");
//     assert.strictEqual(balanceAfter1.toString(), "0");

//   })

//   it('items: listing cannot be created twice', async () => {
//     //nft.approve(exchange.address, '1');
//     //nft.safeTransferFrom(accounts[0], exchange.address, '1');
//     await exchange.putUpForSale("1", "1", "1", "0", token.address, true);

//     await truffleAssert.reverts(
//       exchange.putUpForSale("1", "1", "1", "0", token.address, true),
//       "Cannot create multiple listings for one nft"
//     );
//   })

//   it('items: listing cannot be created twice', async () => {
//     //nft.approve(exchange.address, '1');
//     //nft.safeTransferFrom(accounts[0], exchange.address, '1');
//     await exchange.putUpForSale("1", "1", "1", "0", token.address, true);

//     await truffleAssert.reverts(
//       exchange.putUpForSale("1", "1", "1", "0", token.address, true),
//       "Cannot create multiple listings for one nft"
//     );

//     await truffleAssert.reverts(
//       exchange.putUpForSale("1", "1", "1", "0", token.address, true),
//       "Cannot create multiple listings for one nft"
//     );
//   })

//   it('items: listing cannot be created twice', async () => {
//     //nft.approve(exchange.address, '1');
//     //nft.safeTransferFrom(accounts[0], exchange.address, '1');
//     await exchange.putUpForSale("1", "1", "1", "0", token.address, true);

//     await exchange.pullFromSale("1");

//     await exchange.putUpForSale("1", "1", "1", "0", token.address, true);

//     await truffleAssert.reverts(
//       exchange.putUpForSale("1", "1", "1", "0", token.address, true),
//       "Cannot create multiple listings for one nft"
//     );
//   })

//   it('items: cannnot accept offer that isn\'t yours', async () => {
//     //nft.approve(exchange.address, '1');
//     //nft.safeTransferFrom(accounts[0], exchange.address, '1');
//     await exchange.putUpForSale("1", "1", "1", "0", token.address, true);

//     await exchange.pullFromSale("1");
    
//     await exchange.putUpForSale("1", "1", "1", "0", token.address, true);

//     await truffleAssert.reverts(
//       exchange.putUpForSale("1", "1", "1", "0", token.address, true),
//       "Cannot create multiple listings for one nft"
//     );
//   })

//   it('transaction: offered nfts must have proper ownership', async () => {
//     await nft.safeTransferFrom(accounts[0], accounts[1], "1");
//     await token.transfer(accounts[1], '500');
//     await nft.mint(accounts[0], "https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json");
//     await nft.mint(accounts[0], "https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json");
//     await token.approve(exchange.address, 0, {from: accounts[1]});
//     await token.approve(exchange.address, 100, {from: accounts[1]});
//     //await token.approve(exchange.address, 300);
//     await exof.makeOffer(accounts[1], ['2', '3'], [], '300', ['1'], [], '100', token.address, "1");

//     //Transfer after offer already is created
//     await nft.safeTransferFrom(accounts[1], accounts[0], "1", {from: accounts[1]});

//     let offers = await exof.getOffers.call({from: accounts[1]});
//     let userOffers = await exof.getOffersFromUser(accounts[1]);
//     console.log("UL: " + offers[0]);
//     expect(await offers.length).to.equal(1);
//     expect(offers[0].toString()).to.equal('1');
//     expect(await offers.length).to.equal(1);

//     const balanceBefore = await token.balanceOf.call(accounts[ 0 ]);
//     const balanceBefore1 = await token.balanceOf.call(accounts[ 1 ]);

//     //console.log("ERC20 Balance bef: " + balanceBefore);

//     // let ownedNFTs = await nft.getOwnedNFTs();
//     // let ownedNFTs1 = await nft.getOwnedNFTs({from: accounts[1]});
//     // //console.log("ONFTS: " + JSON.stringify(ownedNFTs));
//     // expect(await ownedNFTs.length).to.equal(2);
//     // expect(await ownedNFTs1.length).to.equal(1);

//     // //console.log("Cur price: " + JSON.stringify(userListings[0].price));
//     // await token.approve(exchange.address, 300);

//     await truffleAssert.reverts(
//     exof.acceptOfferWithERC20('1', {from: accounts[1]}),
//     "Offering account must own all offered NFTs"
//     );

//   })
//})