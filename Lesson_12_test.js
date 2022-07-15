const { expect } = require("chai");
const { ethers } = require("hardhat");

describe('AucEngine', () => {
    let owner,
        logger,
        demo;

    beforeEach(async function() {
        [owner] = await ethers.getSigners();
        const Logger = await ethers.getContractFactory('Logger', owner);
        logger = await Logger.deploy();
        await logger.deployed();

        const Demo = await ethers.getContractFactory('Demo', owner);
        // передаем адрес контракта Logger для взаимодействия с ним
        demo = await Demo.deploy(logger.address);
        await demo.deployed();

        // сам интерфейс нигде разворачивать не нужно
    })

    it('Allows to pay and get payment info', async function() {
        const sum = 100;
        const txDate = {
            value: sum, 
            to: demo.address
        };

        const tx = await owner.sendTransaction(txDate);
        await tx.wait();
        await expect(tx).to.changeEtherBalance(demo, sum);

        const amount = await demo.payment(owner.address, 0);
        expect(amount).to.eq(sum);
    })
})
