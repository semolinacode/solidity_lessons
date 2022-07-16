const { expect } = require("chai");
const { ethers } = require("hardhat");
// подключаем информацию (в том числа abi) к тестам
const tokenJSON = require("../artifacts/contracts/Lesson_13_ERC20.sol/MCSToken.json")

describe('MShop', () => {
    let owner,
        buyer,
        shop,
        erc20;

    beforeEach(async function() {
        [owner, buyer] = await ethers.getSigners();
        const MShop = await ethers.getContractFactory('MShop', owner);
        shop = await MShop.deploy();
        await shop.deployed();

        // подключаемся к существующему контракту
        // передаем адрес токена, abi, от чьего имени всё делаем
        erc20 = new ethers.Contract(await shop.token(), tokenJSON.abi, owner)
    })

    it('Should have an owner and a token', async function() {
        expect(await shop.owner()).to.eq(owner.address);
        // говорим, что в токене должен храниться какой-то адрес
        expect(await shop.token()).to.be.properAddress;
    })

    it("Allows to buy", async function() {
        const tokenAmount = 3;
        const txData = {
            value: tokenAmount,
            to: shop.address
        };

        const tx = await buyer.sendTransaction(txData);
        await tx.wait();

        // чтобы проверить баланс buyer, нужен доступ к функции balanceOf из контракта MCSToken
        expect(await erc20.balanceOf(buyer.address)).to.eq(tokenAmount);
        await expect(() => tx).to.changeEtherBalance(shop, tokenAmount);
        // транзакция привела к возникновению события
        await expect(tx).to.emit(shop, 'Bought').withArgs(tokenAmount, buyer.address);
    })

    it("Allows to sell", async function() {
        const tokensToBuy = 3;
        const tx = await buyer.sendTransaction({
            value: tokensToBuy,
            to: shop.address
        });
        await tx.wait();
        
        const sellAmount = 2;
        // перед продажей нужно разрешить магазину списывать с нас деньги
        const approval = await erc20.connect(buyer).approve(shop.address, sellAmount);
        await approval.wait();

        const sellTx = await shop.connect(buyer).sell(sellAmount);
        await sellTx.wait();
        
        expect(await erc20.balanceOf(buyer.address)).to.eq(tokensToBuy - sellAmount);

        await expect(() => sellTx).to.changeEtherBalance(shop, -sellAmount);
        await expect(sellTx).to.emit(shop, 'Sold').withArgs(sellAmount, buyer.address);
    })
})
