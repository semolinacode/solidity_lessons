const { expect } = require("chai");
const { ethers } = require("hardhat");

describe('AucEngine', () => {
    let owner,
        libDemo;

    beforeEach(async function() {
        [owner] = await ethers.getSigners();
        const LibDemo = await ethers.getContractFactory('LibDemo', owner);
        libDemo = await LibDemo.deploy();
        await libDemo.deployed();
    })

    it('Compares strings', async function() {
        const str1 = 'lalala';
        const str2 = 'lalala';
        const str3 = 'new str';

        const result = await libDemo.runnerStr(str1, str2);
        expect(result).to.eq(true);

        const result2 = await libDemo.runnerStr(str1, str3);
        expect(result2).to.eq(false);
    })

    it('Finds element in array', async function() {
        const result = await libDemo.runnerArr([1, 2, 3], 2);
        expect(result).to.eq(true);

        const result2 = await libDemo.runnerArr([1, 2, 3], 4);
        expect(result2).to.eq(false);
    })
})
