//import chai from 'chai'
//import chaiAsPromised from 'chai-as-promised'
const truffleAssert = require('truffle-assertions');
const chai = require('chai');
const chaiAsPromised = require('chai-as-promised');
chai.use(chaiAsPromised)
const { expect, assert } = chai

var ViridianNFT = artifacts.require("ViridianNFT");
var ViridianPack = artifacts.require("ViridianPack");

contract('Testing ERC721 contract', function(accounts) {

    let token;
    const name = "Viridian Pack";
    const symbol = "VP"

    const account1 = accounts[1]
    const tokenId1 = 1111;
    const tokenUri1 = "This is data for the token 1"; // Does not have to be unique

    const account2 = accounts[2]
    const tokenId2 = 2222;
    const tokenUri2 = "This is data for the token 2"; // Does not have to be unique

    const account3 = accounts[3]

    beforeEach(async () => {
        //console.log(ViridianNFT);
        token = await ViridianNFT.new();
        pack = await ViridianPack.new(token.address);
        token.addAdmin(pack.address);

        await pack.softMintNFT('https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd.json', 0);
        await pack.softMintNFT('https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd1.json', 0);
        await pack.softMintNFT('https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd2.json', 0);
        await pack.softMintNFT('https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json', 0);

        await pack.softMintNFT('https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd.json', 1);
        await pack.softMintNFT('https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd1.json', 1);
        await pack.softMintNFT('https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd2.json', 1);
        await pack.softMintNFT('https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json', 1);

        await pack.softMintNFT('https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd.json', 2);
        await pack.softMintNFT('https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd1.json', 2);
        await pack.softMintNFT('https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd2.json', 2);
        await pack.softMintNFT('https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json', 2);

        await pack.softMintNFT('https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd.json', 3);
        await pack.softMintNFT('https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd1.json', 3);
        await pack.softMintNFT('https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd2.json', 3);
        await pack.softMintNFT('https://viridian-nft-metadata.s3.us-east-2.amazonaws.com/vmd3.json', 3);
    })

    it('should be able to deploy and mint ERC721 token', async () => {
        await pack.mint(account1, tokenUri1, {from: accounts[0]})

        expect(await pack.symbol()).to.equal(symbol)
        expect(await pack.name()).to.equal(name)
    })

    it('should be able to open pack', async () => {
        await pack.mint(account1, tokenUri1, {from: accounts[0]}) //tokenId

        let ownedPacks = await pack.getOwnedNFTs({from: accounts[1]});

        expect(await ownedPacks.length).to.equal(1);

        await pack.openPack(1, {from: accounts[1]});

        let ownedNFTs = await token.getOwnedNFTs({from: accounts[0]})
        let ownedNFTsOther = await token.getOwnedNFTs({from: accounts[1]})
        console.log("ONFTS: " + JSON.stringify(ownedNFTsOther));
        expect(await ownedNFTs.length).to.equal(0);
        expect(await ownedNFTsOther.length).to.equal(3);
        //console.log(JSON.stringify(duplicateTokenID));
        //expect(duplicateTokenID).to.be.rejectedWith(/VM Exception while processing transaction: revert ERC721: owner query for nonexistent token/)
    })

    // it(' should be unique', async () => {
    //     const duplicateTokenID = token.mint(account2, tokenId1, tokenUri2, {from: accounts[0]}) //tokenId
    //     console.log("Create " + JSON.stringify(await duplicateTokenID));
    //     await truffleAssert.reverts(duplicateTokenID, '/VM Exception while processing transaction: revert ERC721: owner query for nonexistent token/');
    //     //console.log(JSON.stringify(duplicateTokenID));
    //     //expect(duplicateTokenID).to.be.rejectedWith(/VM Exception while processing transaction: revert ERC721: owner query for nonexistent token/)
    // })

    // it(' should allow safe transfers', async () => {
    //     //const unownedTokenId = token.safeTransferFrom(account2, account3, tokenId1, {from: accounts[2]}) // tokenId
    //     await truffleAssert.reverts(token.safeTransferFrom(account2, account3, tokenId1, {from: accounts[2]}), 'ERC721: operator query for nonexistent token');
    //     //console.log(unownedTokenId);
    //     //expect(unownedTokenId).to.be.rejectedWith(/VM Exception while processing transaction: revert ERC721: owner query for nonexistent token/)
    //     //expect(await token.ownerOf(tokenId2)).to.equal(account2)

    //     //const wrongOwner = token.safeTransferFrom(account1, account3, tokenId2, {from: accounts[1]}) // wrong owner
    //     //expect(wrongOwner).to.be.rejectedWith(/VM Exception while processing transaction: revert ERC721: operator query for nonexistent token -- Reason given: ERC721: operator query for nonexistent token./)
    //     //expect(await token.ownerOf(tokenId2)).to.equal(account1)

    //     // Noticed that the from gas param needs to be the token owners or it fails
    //     //const wrongFromGas = token.safeTransferFrom(account2, account3, tokenId2, {from: accounts[1]}) // wrong owner
    //     //expect(wrongFromGas).to.be.rejectedWith(/VM Exception while processing transaction: revert ERC721: operator query for nonexistent token -- Reason given: ERC721: operator query for nonexistent token./)
    //     //expect(await token.ownerOf(tokenId2)).to.equal(account2)

    //     await token.safeTransferFrom(account2, account3, tokenId2, {from: accounts[2]})
    //     expect(await token.ownerOf(tokenId2)).to.equal(account3)
    // })
})