const { expect } = require("chai");
const { ethers } = require("hardhat");

describe('AucEngine', () => {
    let owner,
        seller,
        buyer,
        auct;

    beforeEach(async function() {
        [owner, seller, buyer] = await ethers.getSigners();
        const AucEngine = await ethers.getContractFactory('AucEngine', owner);
        auct = await AucEngine.deploy();
        await auct.deployed();
    })

    // пишем сам тест
    it('sets owner', async function() {
        // к полям обращаемся через скобки
        const currentOwner = await auct.owner();
        // console.log(currentOwner);
        expect(currentOwner).to.eq(owner.address);
    })

    // считываем информацию из блокчейна
    async function getTimestamp(blockNumber) {
        return (
            await ethers.provider.getBlock(blockNumber)
        ).timestamp
    }

    async function createAuction(creator, price, discountRate, item, duration) {
        const tx = await auct.connect(creator).createAuction(
            // принимает значение в эфирах и конвертирует в wei
            ethers.utils.parseEther(price.toString()),
            discountRate,
            item,
            duration
        );
        // обращаемся к массиву через () и пишем индекс
        const cAuction = await auct.auctions(0);
        return [cAuction, tx];
    }

    // создаем describe внутри describe просто для логического разделения
    describe('createAuction', () => {
        it('creates auction correctly', async function() {
            const price = 0.0001
            const discountRate = 3;
            const item = 'fake item'
            const duration = 60;
            const [cAuction, tx] = await createAuction(owner, price, discountRate, item, duration);

            // протестируем поля аукциона
            // console.log(cAuction);
            expect(cAuction.item).to.eq(item);
        
            // console.log(tx);
            const ts = await getTimestamp(tx.blockNumber)
            expect(cAuction.startAt).to.eq(ts);
            // тут парсим целые числа так как если к строке прибавить число, произойдет конкатенация...
            expect(parseInt(cAuction.endsAt)).to.eq(parseInt(cAuction.startAt) + duration);
            // тут не парсим числа так как числа и строки в js равны))
            expect(cAuction.endsAt).to.eq(ts + duration);
        })
    })

    function delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    describe('Buy', async function() {
        it('Allows to buy', async function() {
            const price = 0.0001
            const discountRate = 3;
            const item = 'fake item'
            const duration = 60;
            await createAuction(seller, price, discountRate, item, duration);

            // Остановка на 5 секунд
            // Нужно чтобы наш фреймворк для тестирования Mocha не вылетел слишком рано и не сказал "Timeout error"
            // так как Mocha по дефолту имеет маленький таймаут на тест
            // this указывает на текущий тест
            // timeout говорит о том, что тест может работать ДО 5 секунд (иначе будет ошибка)
            this.timeout(5000);
            await delay(1000);

            const buyTx = await auct.connect(buyer).
                buy(0, {value: ethers.utils.parseEther(price.toString())}
            );

            const cAuction = await auct.auctions(0);
            const sellerReceived = cAuction.finalPrice - Math.floor(((cAuction.finalPrice * 10) / 100));
            await expect(buyTx).to.changeEtherBalance(seller, sellerReceived);

            await expect(buyTx)
                .to.emit(auct, 'AuctionEnded').withArgs(0, cAuction.finalPrice, buyer.address);

            // проверяем, что нельзя купить товар после покупки товара
            await expect(
                auct.connect(buyer).buy(0, {value: ethers.utils.parseEther(price.toString())})
            ).to.be.revertedWith('Stopped');
        });
    })
})
