//import chai from 'chai'
//import chaiAsPromised from 'chai-as-promised'
const truffleAssert = require('truffle-assertions');
const chai = require('chai');
const chaiAsPromised = require('chai-as-promised');
//const vtJSON = require('../build/contracts/ViridianToken.json');
chai.use(chaiAsPromised)
const { expect, assert } = chai

var ViridianNFT = artifacts.require("ViridianNFT");
var POI = artifacts.require("ProofOfIntegrity");

contract('Testing ERC721 contract', function(accounts) {

    let token;
    const name = "Viridian NFT";
    const symbol = "VNFT";

    const account1 = accounts[1];
    const tokenId1 = 1111;
    const tokenUri1 = "This is data for the token 1"; // Does not have to be unique

    const account2 = accounts[2];
    const tokenId2 = 2222;
    const tokenUri2 = "This is data for the token 2"; // Does not have to be unique

    const account3 = accounts[3];

    beforeEach(async () => {
        //console.log(ViridianNFT);
        vnft = await ViridianNFT.new(accounts[3], accounts[1], "https://api.viridianexchange.com/pack/", "https://api.viridianexchange.com/vnft/");
        proofOfIntegrity = await POI.new();
    })

    // it('should be able to deploy and mint ERC721 token', async () => {
    //     await vnft.mint(account1, tokenUri1, {from: accounts[0]})

    //     expect(await vnft.symbol()).to.equal(symbol)
    //     expect(await vnft.name()).to.equal(name)
    // })

    it('should be able to mint vnft', async () => {
        console.log("OWNER: " + accounts[0]);
        await vnft.setPublicMinting(true, {from: accounts[0]});
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(2, accounts[0], {from: accounts[0], value: 400000000000000000}); //tokenId

        //await vnft.lockInPackResult(1, {from: accounts[0]});

        let ownedPacks = await vnft.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);
    })

    it('should be able to see what NFTs are owned', async () => {
        console.log("OWNER: " + accounts[0]);
        await vnft.setPublicMinting(true, {from: accounts[0]});
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(2, accounts[0], {from: accounts[0], value: 400000000000000000}); //tokenId

        //await vnft.lockInPackResult(1, {from: accounts[0]});

        let ownedPacks = await vnft.getOwnedNFTs({from: accounts[0]});

        expect(Number.parseInt(ownedPacks[0])).to.equal(123);
        expect(Number.parseInt(ownedPacks[1])).to.equal(124);
    })

    it('vnft URI should have correct index', async () => {
        console.log("OWNER: " + accounts[0]);
        await vnft.setPublicMinting(true, {from: accounts[0]});
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(2, accounts[0], {from: accounts[0], value: 400000000000000000}); //tokenId

        //await vnft.lockInPackResult(1, {from: accounts[0]});

        let ownedPacks = await vnft.getOwnedNFTs({from: accounts[0]});

        expect(await vnft.tokenURI(Number.parseInt(ownedPacks[0]))).to
        .equal("https://api.viridianexchange.com/vnft/1");

        expect(await vnft.tokenURI(Number.parseInt(ownedPacks[1]))).to
        .equal("https://api.viridianexchange.com/vnft/2");
    })

    it('should allow safe transfers', async () => {
        console.log("OWNER: " + accounts[0]);
        await vnft.setPublicMinting(true, {from: accounts[0]});
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(2, accounts[0], {from: accounts[0], value: 400000000000000000}); //tokenId

        //await vnft.lockInPackResult(1, {from: accounts[0]});

        let ownedPacks = await vnft.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);

        await vnft.safeTransferFrom(accounts[0], accounts[1], 123, {from: accounts[0]})
        expect(await vnft.ownerOf(123)).to.equal(accounts[1])
    })

    it('should be able open vnft and recieve viridian nft', async () => {
        console.log("OWNER: " + await token.owner());

        await token.addAdmin(vnft.address, {from: accounts[0]});
        await vnft.setPublicMinting(true, {from: accounts[0]});
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(2, accounts[0], {from: accounts[0], value: 400000000000000000}); //tokenId

        //await vnft.lockInPackResult(1, {from: accounts[0]});

        let ownedPacks = await vnft.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);

        await vnft.allowOpening();

        await vnft.openPack(123);

        ownedPacks = await vnft.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(1);

        let ownedVNFTs = await token.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedVNFTs)).to.equal(1);
    })

    it('token URI of nft should follow correct format', async () => {
        console.log("OWNER: " + await token.owner());
        
        await token.addAdmin(vnft.address, {from: accounts[0]});
        await vnft.setPublicMinting(true, {from: accounts[0]});
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(2, accounts[0], {from: accounts[0], value: 400000000000000000}); //tokenId

        await token.setBaseURI("https://api.viridianexchange.com/vnft/");

        //await vnft.lockInPackResult(1, {from: accounts[0]});

        let ownedPacks = await vnft.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);

        await vnft.allowOpening();

        await vnft.openPack(123);

        ownedPacks = await vnft.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(1);

        let ownedVNFTs = await token.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedVNFTs)).to.equal(1);

        console.log(await token.tokenURI(123));

        expect(await token.tokenURI(123)).to.equal("https://api.viridianexchange.com/vnft/123");
    })

    it('Proof of integrity should work', async () => {
        let poiInt = await proofOfIntegrity.generateProof("Pokemon | PSA | Breh | 1234421", 7843925748932754);

        console.log("Proof of integrity tokenId: " + poiInt.toString());

        expect(await proofOfIntegrity.verifyProof(poiInt, "Pokemon | PSA | Breh | 1234421", 7843925748932754)).to.equal(true);
    });
})