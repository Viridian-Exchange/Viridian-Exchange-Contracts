//import chai from 'chai'
//import chaiAsPromised from 'chai-as-promised'
const truffleAssert = require('truffle-assertions');
const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');
const chai = require('chai');
const chaiAsPromised = require('chai-as-promised');
//const vtJSON = require('../build/contracts/ViridianToken.json');
chai.use(chaiAsPromised)
const { expect, assert } = chai

var ViridianNFT = artifacts.require("ViridianNFT");
var ViridianNFTMockUpgradable = artifacts.require("ViridianNFTMockUpgradable");
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

    const convRate = 2;

    beforeEach(async () => {
        //console.log(ViridianNFT);
        //vnft = await ViridianNFT.new();
        proofOfIntegrity = await POI.new();

        console.log(ViridianNFT);

        vnft = await deployProxy(ViridianNFT, [accounts[3], accounts[3], accounts[1], accounts[1], "https://api.viridianexchange.com/pack/", "https://api.viridianexchange.com/vnft/", 3000], {});

        await vnft.setConvRate(2);
    })

    it('upgrading is functional', async () => {
        //const box = await deployProxy(ViridianNFT, [accounts[3], accounts[1], "https://api.viridianexchange.com/pack/", "https://api.viridianexchange.com/vnft/"], {});
        const vnft2 = await upgradeProxy(vnft.address, ViridianNFTMockUpgradable);
    
        const value = await vnft2.treasury();
        assert.equal(value, accounts[1]);
        // TODO: Figure out if this is supposed to change
        // const maxMint = await vnft2.maxMintAmt();
        // assert.equal(maxMint.toString(), "3000");
      });

    it('should be able to deploy ERC721 Token', async () => {
        expect(await vnft.symbol()).to.equal(symbol);
        expect(await vnft.name()).to.equal(name);
    })

    it('should be able to deploy ERC721 Token', async () => {
        let approved = await vnft.isApprovedForAll(vnft.address, accounts[3]);
        assert.equal(approved, false);
        await vnft.addAdmin(accounts[3]);
        approved = await vnft.isApprovedForAll(vnft.address, accounts[3]);
        assert.equal(approved, true);
    })

    it('should be able to mint vnft', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setPublicMinting(true, {from: await accounts[0]});
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(2, accounts[0], {from: accounts[0], value: 400000000000000000 * convRate}); //tokenId

        //await vnft.lockInPackResult(1, {from: accounts[0]});

        let ownedPacks = await vnft.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);
    })

    it('ownership should be correctly enforced after minting', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setPublicMinting(true, {from: accounts[0]});
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(2, accounts[0], {from: accounts[0], value: 400000000000000000 * convRate}); //tokenId

        let owner1 = await vnft.ownerOf(1, {from: accounts[0]});
        let owner2 = await vnft.ownerOf(2, {from: accounts[0]});

        expect(owner1).to.equal(accounts[0]);
        expect(owner2).to.equal(accounts[0]);
    })

    it('vnft URI should have correct index', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setPublicMinting(true, {from: accounts[0]});
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(2, accounts[0], {from: accounts[0], value: 400000000000000000 * convRate}); //tokenId

        expect(await vnft.tokenURI(1)).to
        .equal("https://api.viridianexchange.com/pack/1");

        expect(await vnft.tokenURI(2)).to
        .equal("https://api.viridianexchange.com/pack/2");
    })

    it('should allow safe transfers', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setPublicMinting(true, {from: accounts[0]});
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(2, accounts[0], {from: accounts[0], value: 400000000000000000 * convRate}); //tokenId

        let ownedPacks = await vnft.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);

        console.log("TOBI: " + JSON.stringify(await vnft.tokenOfOwnerByIndex(accounts[0], 0)));

        await vnft.safeTransferFrom(accounts[0], accounts[1], 1, {from: accounts[0]})
        console.log("TOBI: " + JSON.stringify(await vnft.tokenOfOwnerByIndex(accounts[0], 0)));
        console.log("TOBI2: " + JSON.stringify(await vnft.tokenOfOwnerByIndex(accounts[1], 0)));
        expect(await vnft.ownerOf(1)).to.equal(accounts[1]);
    });

    it('should be able open vnft', async () => {
        console.log("OWNER: " + await vnft.owner());

        await vnft.addAdmin(vnft.address, {from: accounts[0]});
        await vnft.setPublicMinting(true, {from: accounts[0]});
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(2, accounts[0], {from: accounts[0], value: 400000000000000000 * convRate}); //tokenId

        //await vnft.lockInPackResult(1, {from: accounts[0]});

        let ownedPacks = await vnft.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);

        await vnft.allowOpening();

        await vnft.open(1);

        ownedPacks = await vnft.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);
    })

    it('token URI of nft should follow correct format', async () => {
        console.log("OWNER: " + await vnft.owner());
        
        await vnft.setPublicMinting(true, {from: accounts[0]});
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(2, accounts[0], {from: accounts[0], value: 400000000000000000 * convRate}); //tokenId

        //await vnft.setBaseURI("https://api.viridianexchange.com/pack/");

        //await vnft.lockInPackResult(1, {from: accounts[0]});

        let ownedPacks = await vnft.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);

        await vnft.allowOpening();

        await vnft.open(1);

        ownedPacks = await vnft.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);

        console.log(await vnft.tokenURI(123));

        expect(await vnft.tokenURI(123)).to.equal("https://api.viridianexchange.com/vnft/123");
        expect(await vnft.tokenURI(2)).to.equal("https://api.viridianexchange.com/pack/2");
    })

    it('should be able to mint one nft when allocated that in whitelist', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setWhitelistMinting(true, {from: await accounts[0]});
        await vnft.setWhitelist([accounts[1]], 1, 0)
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(1, accounts[1], {from: accounts[1], value: 200000000000000000 * convRate}); //tokenId

        let ownedPacks = await vnft.balanceOf(accounts[1], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(1);
    })

    it('should be able to mint two nfts when allocated two in whitelist', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setWhitelistMinting(true, {from: await accounts[0]});
        await vnft.setWhitelist([accounts[1]], 2, 0)
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(2, accounts[1], {from: accounts[1], value: 400000000000000000 * convRate}); //tokenId

        let ownedPacks = await vnft.balanceOf(accounts[1], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);
    })

    it('should be able to mint one nfts twice when allocated two in whitelist', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setWhitelistMinting(true, {from: await accounts[0]});
        await vnft.setWhitelist([accounts[1]], 2, 0)
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(1, accounts[1], {from: accounts[1], value: 200000000000000000 * convRate}); //tokenId
        await vnft.mint(1, accounts[1], {from: accounts[1], value: 200000000000000000 * convRate}); //tokenId

        console.log("Balance of: " + await vnft.balanceOf(accounts[1], {from: accounts[0]}))

        let ownedPacks = await vnft.balanceOf(accounts[1], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);
    })

    it('Should revert if a Third NFT is minted over allocation', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setWhitelistMinting(true, {from: await accounts[0]});
        await vnft.setWhitelist([accounts[1]], 2, 0)
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await vnft.mint(1, accounts[1], {from: accounts[1], value: 200000000000000000 * convRate}); //tokenId
        await vnft.mint(1, accounts[1], {from: accounts[1], value: 200000000000000000 * convRate}); //tokenId

        let ownedPacks = await vnft.balanceOf(accounts[1], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);

        await truffleAssert.reverts(
            vnft.mint(1, accounts[1], {from: accounts[1], value: 200000000000000000 * convRate}),
            "Minting not enabled or not on lists / minting over list limits"
        );
    })

    it('Should revert if a Third NFT is minted over allocation', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setWhitelistMinting(true, {from: await accounts[0]});
        await vnft.setWhitelist([accounts[1]], 2, 0)
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        // await vnft.mint(1, accounts[1], {from: accounts[1], value: 200000000000000000 * convRate}); //tokenId
        // await vnft.mint(1, accounts[1], {from: accounts[1], value: 200000000000000000 * convRate}); //tokenId

        // let ownedPacks = await vnft.balanceOf(accounts[1], {from: accounts[0]});

        // expect(Number.parseInt(ownedPacks)).to.equal(2);

        await truffleAssert.reverts(
            vnft.mint(3, accounts[1], {from: accounts[1], value: 600000000000000000 * convRate}),
            "Minting not enabled or not on lists / minting over list limits"
        );
    })

    it('Should revert if a Third NFT is minted over allocation', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setWhitelistMinting(true, {from: await accounts[0]});
        await vnft.setWhitelist([accounts[1]], 1, 0)
        await vnft.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        // await vnft.mint(1, accounts[1], {from: accounts[1], value: 200000000000000000 * convRate}); //tokenId
        // await vnft.mint(1, accounts[1], {from: accounts[1], value: 200000000000000000 * convRate}); //tokenId

        // let ownedPacks = await vnft.balanceOf(accounts[1], {from: accounts[0]});

        // expect(Number.parseInt(ownedPacks)).to.equal(2);

        await truffleAssert.reverts(
            vnft.mint(2, accounts[1], {from: accounts[1], value: 400000000000000000 * convRate}),
            "Minting not enabled or not on lists / minting over list limits"
        );
    })

    it('new drop should change base URI', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setPublicMinting(true, {from: accounts[0]});
        await vnft.setHashedTokenIds([123, 124, 125, 126], 1, 3, {from: accounts[0]});
        await vnft.mint(2, accounts[0], {from: accounts[0], value: 400000000000000000 * convRate}); //tokenId

        await vnft.newDrop(2, (400000000000000000).toString(), "https://api.viridianexchange.com/v2/pack/", "https://api.viridianexchange.com/v2/vnft/", {from: accounts[0]});
        await vnft.setPublicMinting(true, {from: accounts[0]});
        await vnft.setHashedTokenIds([125, 126], 1, 2, {from: accounts[0]});

        await vnft.mint(2, accounts[0], {from: accounts[0], value: 800000000000000000 * convRate}); //tokenId

        expect(await vnft.tokenURI(1)).to
        .equal("https://api.viridianexchange.com/pack/1");

        expect(await vnft.tokenURI(2)).to
        .equal("https://api.viridianexchange.com/pack/2");

        expect(await vnft.tokenURI(3)).to
        .equal("https://api.viridianexchange.com/v2/pack/3");

        expect(await vnft.tokenURI(4)).to
        .equal("https://api.viridianexchange.com/v2/pack/4");

        
    })

    it('new drop should change base URI', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setPublicMinting(true, {from: accounts[0]});
        await vnft.setHashedTokenIds([123, 124, 125, 126], 1, 3, {from: accounts[0]});
        await vnft.mint(2, accounts[0], {from: accounts[0], value: 400000000000000000 * convRate}); //tokenId

        await vnft.newDrop(2, (400000000000000000).toString(), "https://api.viridianexchange.com/v2/pack/", "https://api.viridianexchange.com/v2/vnft/", {from: accounts[0]});
        await vnft.setPublicMinting(true, {from: accounts[0]});
        await vnft.setHashedTokenIds([125, 126], 1, 2, {from: accounts[0]});

        await vnft.mint(2, accounts[0], {from: accounts[0], value: 800000000000000000 * convRate}); //tokenId

        expect(await vnft.tokenURI(1)).to
        .equal("https://api.viridianexchange.com/pack/1");

        expect(await vnft.tokenURI(2)).to
        .equal("https://api.viridianexchange.com/pack/2");

        expect(await vnft.tokenURI(3)).to
        .equal("https://api.viridianexchange.com/v2/pack/3");

        expect(await vnft.tokenURI(4)).to
        .equal("https://api.viridianexchange.com/v2/pack/4");

        
    })

    it('should be able to do two drops after the first', async () => {
        console.log("OWNER: " + await vnft.owner());
        await vnft.setPublicMinting(true, {from: accounts[0]});
        await vnft.setHashedTokenIds([123, 124, 125, 126], 1, 3, {from: accounts[0]});
        await vnft.mint(2, accounts[0], {from: accounts[0], value: 400000000000000000 * convRate}); //tokenId

        await vnft.newDrop(2, (400000000000000000).toString(), "https://api.viridianexchange.com/v2/pack/", "https://api.viridianexchange.com/v2/vnft/", {from: accounts[0]});
        await vnft.setPublicMinting(true, {from: accounts[0]});
        await vnft.setHashedTokenIds([125, 126], 1, 2, {from: accounts[0]});

        await vnft.mint(2, accounts[0], {from: accounts[0], value: 800000000000000000 * convRate}); //tokenId

        await vnft.newDrop(2, (800000000000000000).toString(), "https://api.viridianexchange.com/v3/pack/", "https://api.viridianexchange.com/v3/vnft/", {from: accounts[0]});
        await vnft.setPublicMinting(true, {from: accounts[0]});
        await vnft.setHashedTokenIds([127, 128], 1, 2, {from: accounts[0]});

        await vnft.mint(2, accounts[0], {from: accounts[0], value: 1600000000000000000 * convRate}); //tokenId

        expect(await vnft.tokenURI(1)).to
        .equal("https://api.viridianexchange.com/pack/1");

        expect(await vnft.tokenURI(2)).to
        .equal("https://api.viridianexchange.com/pack/2");

        expect(await vnft.tokenURI(3)).to
        .equal("https://api.viridianexchange.com/v2/pack/3");

        expect(await vnft.tokenURI(4)).to
        .equal("https://api.viridianexchange.com/v2/pack/4");

        expect(await vnft.tokenURI(5)).to
        .equal("https://api.viridianexchange.com/v3/pack/5");

        expect(await vnft.tokenURI(6)).to
        .equal("https://api.viridianexchange.com/v3/pack/6");

        
    })

    it('Proof of integrity should work', async () => {
        let poiInt = await proofOfIntegrity.generateProof("Pokemon | PSA | Breh | 1234421", 7843925748932754);

        console.log("Proof of integrity tokenId: " + poiInt.toString());

        expect(await proofOfIntegrity.verifyProof(poiInt, "Pokemon | PSA | Breh | 1234421", 7843925748932754)).to.equal(true);
    });
})