//import chai from 'chai'
//import chaiAsPromised from 'chai-as-promised'
const truffleAssert = require('truffle-assertions');
//const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const chai = require('chai');
const chaiAsPromised = require('chai-as-promised');
//const vtJSON = require('../build/contracts/ViridianToken.json');
chai.use(chaiAsPromised)
const { expect, assert } = chai

var ViridianNFT = artifacts.require("ViridianNFTOmniChain");
var POI = artifacts.require("ProofOfIntegrity");

contract('Testing ERC721 contract', function(accounts) {

    let vnft;
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
        //vnft = await ViridianNFT.new();
        proofOfIntegrity = await POI.new();

        vnft = await ViridianNFT.new(accounts[3], accounts[1], "https://api.viridianexchange.com/pack/", "https://api.viridianexchange.com/vnft/");
    })

    it('should be able to deploy ERC721 Token', async () => {
        expect(await vnft.symbol()).to.equal(symbol)
        expect(await vnft.name()).to.equal(name)
    })

    it('should be able to mint vnft', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setPublicMinting(true, {from: await accounts[0]});
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(2, accounts[0], {from: accounts[0], value: 400000000000000000}); //tokenId

        //await vnft.lockInPackResult(1, {from: accounts[0]});

        let ownedPacks = await vnft.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);
    })

    it('ownership should be correctly enforced after minting', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setPublicMinting(true, {from: accounts[0]});
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(2, accounts[0], {from: accounts[0], value: 400000000000000000}); //tokenId

        //await vnft.lockInPackResult(1, {from: accounts[0]});

        let owner1 = await vnft.ownerOf(123, {from: accounts[0]});
        let owner2 = await vnft.ownerOf(124, {from: accounts[0]});

        expect(owner1).to.equal(accounts[0]);
        expect(owner2).to.equal(accounts[0]);
    })

    it('vnft URI should have correct index', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setPublicMinting(true, {from: accounts[0]});
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(2, accounts[0], {from: accounts[0], value: 400000000000000000}); //tokenId

        expect(await vnft.tokenURI(123)).to
        .equal("https://api.viridianexchange.com/pack/1");

        expect(await vnft.tokenURI(124)).to
        .equal("https://api.viridianexchange.com/pack/2");
    })

    it('should allow safe transfers', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setPublicMinting(true, {from: accounts[0]});
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(2, accounts[0], {from: accounts[0], value: 400000000000000000}); //tokenId

        let ownedPacks = await vnft.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);

        await vnft.safeTransferFrom(accounts[0], accounts[1], 123, {from: accounts[0]})
        expect(await vnft.ownerOf(123)).to.equal(accounts[1])
    })

    it('should be able open vnft', async () => {
        console.log("OWNER: " + await vnft.owner());

        await vnft.addAdmin(vnft.address, {from: accounts[0]});
        await vnft.setPublicMinting(true, {from: accounts[0]});
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(2, accounts[0], {from: accounts[0], value: 400000000000000000}); //tokenId

        //await vnft.lockInPackResult(1, {from: accounts[0]});

        let ownedPacks = await vnft.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);

        await vnft.allowOpening();

        await vnft.open(123);

        ownedPacks = await vnft.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);
    })

    it('token URI of nft should follow correct format', async () => {
        console.log("OWNER: " + await vnft.owner());
        
        await vnft.setPublicMinting(true, {from: accounts[0]});
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(2, accounts[0], {from: accounts[0], value: 400000000000000000}); //tokenId

        //await vnft.setBaseURI("https://api.viridianexchange.com/pack/");

        //await vnft.lockInPackResult(1, {from: accounts[0]});

        let ownedPacks = await vnft.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);

        await vnft.allowOpening();

        await vnft.open(123);

        ownedPacks = await vnft.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);

        console.log(await vnft.tokenURI(123));

        expect(await vnft.tokenURI(123)).to.equal("https://api.viridianexchange.com/vnft/123");
        expect(await vnft.tokenURI(124)).to.equal("https://api.viridianexchange.com/pack/2");
    })

    it('should be able to mint vnft on whitelist in free tier', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setWhitelistMinting(true, {from: await accounts[0]});
        await vnft.setWhitelist([accounts[1]], 1, 0)
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(1, accounts[1], {from: accounts[1]}); //tokenId

        let ownedPacks = await vnft.balanceOf(accounts[1], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(1);
    })

    it('should be able to mint one nft when allocated that in whitelist', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setWhitelistMinting(true, {from: await accounts[0]});
        await vnft.setWhitelist([accounts[1]], 2, 0)
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(1, accounts[1], {from: accounts[1], value: 200000000000000000}); //tokenId

        let ownedPacks = await vnft.balanceOf(accounts[1], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(1);
    })

    it('should be able to mint two nfts when allocated two in whitelist', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setWhitelistMinting(true, {from: await accounts[0]});
        await vnft.setWhitelist([accounts[1]], 3, 0)
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(2, accounts[1], {from: accounts[1], value: 400000000000000000}); //tokenId

        let ownedPacks = await vnft.balanceOf(accounts[1], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);
    })

    it('should be able to mint one nfts twice when allocated two in whitelist', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setWhitelistMinting(true, {from: await accounts[0]});
        await vnft.setWhitelist([accounts[1]], 3, 0)
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(1, accounts[1], {from: accounts[1], value: 200000000000000000}); //tokenId
        await vnft.mint(1, accounts[1], {from: accounts[1], value: 200000000000000000}); //tokenId

        let ownedPacks = await vnft.balanceOf(accounts[1], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);
    })

    it('Should revert if a Third NFT is minted over allocation', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setWhitelistMinting(true, {from: await accounts[0]});
        await vnft.setWhitelist([accounts[1]], 3, 0)
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(1, accounts[1], {from: accounts[1], value: 200000000000000000}); //tokenId
        await vnft.mint(1, accounts[1], {from: accounts[1], value: 200000000000000000}); //tokenId

        let ownedPacks = await vnft.balanceOf(accounts[1], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);

        await truffleAssert.reverts(
            vnft.mint(1, accounts[1], {from: accounts[1], value: 200000000000000000}),
            "Minting not enabled or not on whitelist / trying to mint more than allowed by the whitelist"
        );
    })

    it('Should revert if a Third NFT is minted over allocation', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setWhitelistMinting(true, {from: await accounts[0]});
        await vnft.setWhitelist([accounts[1]], 3, 0)
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        // await vnft.mint(1, accounts[1], {from: accounts[1], value: 200000000000000000}); //tokenId
        // await vnft.mint(1, accounts[1], {from: accounts[1], value: 200000000000000000}); //tokenId

        // let ownedPacks = await vnft.balanceOf(accounts[1], {from: accounts[0]});

        // expect(Number.parseInt(ownedPacks)).to.equal(2);

        await truffleAssert.reverts(
            vnft.mint(3, accounts[1], {from: accounts[1], value: 200000000000000000}),
            "Cannot mint more NFTs than your whitelist limit."
        );
    })

    it('Should revert if a Third NFT is minted over allocation', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setWhitelistMinting(true, {from: await accounts[0]});
        await vnft.setWhitelist([accounts[1]], 2, 0)
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        // await vnft.mint(1, accounts[1], {from: accounts[1], value: 200000000000000000}); //tokenId
        // await vnft.mint(1, accounts[1], {from: accounts[1], value: 200000000000000000}); //tokenId

        // let ownedPacks = await vnft.balanceOf(accounts[1], {from: accounts[0]});

        // expect(Number.parseInt(ownedPacks)).to.equal(2);

        await truffleAssert.reverts(
            vnft.mint(2, accounts[1], {from: accounts[1], value: 200000000000000000}),
            "Cannot mint more NFTs than your whitelist limit."
        );
    })

    it('Should revert if a Third NFT is minted over allocation', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setWhitelistMinting(true, {from: await accounts[0]});
        await vnft.setWhitelist([accounts[1]], 1, 0)
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        // await vnft.mint(1, accounts[1], {from: accounts[1], value: 200000000000000000}); //tokenId
        // await vnft.mint(1, accounts[1], {from: accounts[1], value: 200000000000000000}); //tokenId

        // let ownedPacks = await vnft.balanceOf(accounts[1], {from: accounts[0]});

        // expect(Number.parseInt(ownedPacks)).to.equal(2);

        await truffleAssert.reverts(
            vnft.mint(2, accounts[1], {from: accounts[1]}),
            "Cannot mint more than 1 NFT in the free minting tier."
        );
    })

    it('Proof of integrity should work', async () => {
        let poiInt = await proofOfIntegrity.generateProof("Pokemon | PSA | Breh | 1234421", 7843925748932754);

        console.log("Proof of integrity tokenId: " + poiInt.toString());

        expect(await proofOfIntegrity.verifyProof(poiInt, "Pokemon | PSA | Breh | 1234421", 7843925748932754)).to.equal(true);
    });
})