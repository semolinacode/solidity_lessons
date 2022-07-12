const { expect } = require("chai");
const { ethers } = require("hardhat");

describe('Payments', () => {
    let owner,
        other_addr,
        demo;

    beforeEach(async function() {
        [owner, other_addr] = await ethers.getSigners();
        const DemoContract = await ethers.getContractFactory('Demo', owner);
        demo = await DemoContract.deploy();
        await demo.deployed();
    })

    async function sendMoney(sender) {
        let amount = 200;
        const txDate = {
            // имя функции писать не будем так как тестируем функцию receive
            to: demo.address,
            value: amount
        };

        const tx = await sender.sendTransaction(txDate);
        await tx.wait();
        return [tx, amount];
    }

    // пишем сам тест
    it('Should allow to send money', async function() {
        const [sendMoneyTx, amount] = await sendMoney(other_addr);
        // console.log(sendMoneyTx, amount);
        await expect(() => sendMoneyTx).to.changeEtherBalance(demo, amount);
    })

    // делаем проверку на отправку события и правильность заполнения полей события
    it ('Should the event go', async function() {
        const [sendMoneyTx, amount] = await sendMoney(other_addr);
        // в нашем случае provider - hardhat  
        // getBlock - дает информацию облоке по номеру блока
        // номер блока берем из транзакции
        const timestamp = (
            await ethers.provider.getBlock(sendMoneyTx.blockNumber)
        ).timestamp;
    
        await expect(sendMoneyTx).to.emit(demo, 'Paid').withArgs(other_addr.address, amount, timestamp);
    })

    // проверка, что деньги может снимать только владелец
    it('Should allow owner to withdraw funds', async function() {
        const [_, amount] = await sendMoney(other_addr);

        // withdraw - функция нашего контракта 
        // по умолчанию функция будет вызвана от адреса, который доступен первым в списке адресов (то етсть адрес создателя контракта)
        const tx = await demo.withdraw(owner.address);
        await expect(tx).changeEtherBalances([demo, owner], [-amount, amount]);
    })

    it('Should not allow another account to withdraw funds', async function() {
        const [_, amount] = await sendMoney(other_addr);

        // ждем, что транзакция будет откачена с такой ошибкой
        await expect(
            demo.connect(other_addr).withdraw(owner.address)
        ).to.be.revertedWith('You are not an owner!!');
    })
})
