const { expect } = require("chai");
const { ethers } = require("hardhat");

// функция describe описывает тест
// первый аргумент: название теста
// второй аргумент: функция тестирования
// внутри будут вызываться it() - конкретные проверки значений функций главной программы
describe('Payments', () => {
    let acc1,
        acc2,
        payments;

    // перед каждым действием будет выполняться функции коллбек
    // то есть перед каждым тестом будет разворачиваться новый контракт и все тесты будут изолированы
    beforeEach(async function() {
        // hardhat предлагает несколько демо аккаунтов как и ремикс
        // получаем информацию об этих аккаунтах
        [acc1, acc2] = await ethers.getSigners();
        // получить информацию о скомпилированной версии смарт контракта
        // в функцию передам название смарт контракта и аккаунт, от чьего имени будем разворачивать контракт
        const Payments = await ethers.getContractFactory('Payments', acc1);
        // разворачиваем смарт контракт
        // на этом шаге мы просто отправляем транзакцию
        // возвращает объект, с помощью которого будем взаимодействовать со смарт контрактом 
        payments = await Payments.deploy();
        // на этом шаге ждем, когда транзакиця будет выполнена
        await payments.deployed();

        // вывести адрес контракта
        // console.log(payments.address);
    })

    // пишем сам тест
    it('Should be deployed', async function() {
        // console.log('Success!!');

        // проверяем адрес на правильность
        expect(payments.address).to.be.properAddress;
    })

    it('Should have 0 Ether by default', async function() {
        const balance = await payments.currentBalance();
        // console.log(balance);
        expect(balance).to.eq(0);
    })

    it('Should be possible to send funds', async function() {
        // tx - транзакция
        // транзакция отправится с первого аккаунта (acc1)
        const value = 100;
        const value2 = 200;
        const tx = await payments.pay('First pay', { value: value });

        await expect(() => tx).to.changeEtherBalance(acc1, -value);

        // ожидаем выполнение транзакции
        await tx.wait();

        // отправим ту же транзакцию со второго аккаунта
        const msg = 'Second pay';
        const tx2 = await payments.connect(acc2).pay(msg, { value: value2 });    
        await tx2.wait();

        // проверим, что на аккаунте стало меньше, а на балансе смарт контракта больше
        await expect(() => tx2).to.changeEtherBalances([acc2, payments], [-value2, value2]);

        // const balance = await payments.currentBalance();
        // console.log(balance);

        // тут же затестим getPayment
        // getPayment будет отправлена как вызов, а не как транзакция. Поэтому писать wait() не нужно
        const newPayment = await payments.getPayment(acc2.address, 0);
        // console.log(newPayment);
        expect(newPayment.message).to.eq(msg);
        expect(newPayment.amount).to.eq(value2);
        expect(newPayment.from).to.eq(acc2.address);
    })
})
