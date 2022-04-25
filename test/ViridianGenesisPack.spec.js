//import chai from 'chai'
//import chaiAsPromised from 'chai-as-promised'
const truffleAssert = require('truffle-assertions');
const chai = require('chai');
const chaiAsPromised = require('chai-as-promised');
//const vtJSON = require('../build/contracts/ViridianToken.json');
chai.use(chaiAsPromised)
const { expect, assert } = chai

var ViridianNFT = artifacts.require("ViridianNFT");
var ViridianPack = artifacts.require("ViridianGenesisPack");
//var VRF = artifacts.require("RandomNumberConsumer");

contract('Testing ERC721 contract', function(accounts) {

    let token;
    const name = "Viridian Pack";
    const symbol = "VP";

    const account1 = accounts[1];
    const tokenId1 = 1111;
    const tokenUri1 = "This is data for the token 1"; // Does not have to be unique

    const account2 = accounts[2];
    const tokenId2 = 2222;
    const tokenUri2 = "This is data for the token 2"; // Does not have to be unique

    const account3 = accounts[3];

    beforeEach(async () => {
        //console.log(ViridianNFT);
        token = await ViridianNFT.new(accounts[2]);
        pack = await ViridianPack.new(token.address, token.address, "https://api.viridianexchange.com/pack/");
        //vrf = await VRF.new(pack.address);
        //token.addAdmin(pack.address, {from: accounts[0]});
        //pack.configureVRF(vrf.address);

        // const linkContractAddress = '0x326C977E6efc84E512bB9C30f76E30c160eD06FB';
        // let vtABI = new web3.eth.Contract(vtJSON['abi'], linkContractAddress);

        // await vtABI.methods.transfer(vrf.address, '5000000000000000').send.request({from: accounts[0]});
    })

    // it('should be able to deploy and mint ERC721 token', async () => {
    //     await pack.mint(account1, tokenUri1, {from: accounts[0]})

    //     expect(await pack.symbol()).to.equal(symbol)
    //     expect(await pack.name()).to.equal(name)
    // })

    it('should be able to mint pack', async () => {
        console.log("OWNER: " + accounts[0]);
        await pack.setPublicMinting(true, {from: accounts[0]});
        await pack.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await pack.mint(2, {from: accounts[0]}); //tokenId

        //await pack.lockInPackResult(1, {from: accounts[0]});

        let ownedPacks = await pack.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);
    })

    it('should allow safe transfers', async () => {
        console.log("OWNER: " + accounts[0]);
        await pack.setPublicMinting(true, {from: accounts[0]});
        await pack.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await pack.mint(2, {from: accounts[0]}); //tokenId

        //await pack.lockInPackResult(1, {from: accounts[0]});

        let ownedPacks = await pack.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);

        await pack.safeTransferFrom(accounts[0], accounts[1], 123, {from: accounts[0]})
        expect(await pack.ownerOf(123)).to.equal(accounts[1])
    })

    it('should be able open pack and recieve viridian nft', async () => {
        console.log("OWNER: " + await token.owner());

        await token.addAdmin(pack.address, {from: accounts[0]});
        await pack.setPublicMinting(true, {from: accounts[0]});
        await pack.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await pack.mint(2, {from: accounts[0]}); //tokenId

        //await pack.lockInPackResult(1, {from: accounts[0]});

        let ownedPacks = await pack.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);

        await pack.allowOpening();

        await pack.openPack(123);

        ownedPacks = await pack.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(1);

        let ownedVNFTs = await token.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedVNFTs)).to.equal(1);
    })

    it('token URI of nft should follow correct format', async () => {
        console.log("OWNER: " + await token.owner());
        
        await token.addAdmin(pack.address, {from: accounts[0]});
        await pack.setPublicMinting(true, {from: accounts[0]});
        await pack.setHashedTokenIds([123, 124, 125], 1, 3, {from: accounts[0]});
        await pack.mint(2, {from: accounts[0]}); //tokenId

        await token.setBaseURI("https://api.viridianexchange.com/vnft/");

        //await pack.lockInPackResult(1, {from: accounts[0]});

        let ownedPacks = await pack.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(2);

        await pack.allowOpening();

        await pack.openPack(123);

        ownedPacks = await pack.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedPacks)).to.equal(1);

        let ownedVNFTs = await token.balanceOf(accounts[0], {from: accounts[0]});

        expect(Number.parseInt(ownedVNFTs)).to.equal(1);

        console.log(await token.tokenURI(123));

        expect(await token.tokenURI(123)).to.equal("https://api.viridianexchange.com/vnft/123");
    })
})